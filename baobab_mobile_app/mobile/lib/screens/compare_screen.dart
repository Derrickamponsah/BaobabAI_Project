import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/compare_service.dart';
import '../theme/app_theme.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  List<CompareItem> get _items => CompareService.instance.items;

  void _remove(int index) {
    CompareService.instance.removeItem(index);
    setState(() {});
  }

  void _clearAll() {
    CompareService.instance.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Trees'),
        actions: [
          if (_items.isNotEmpty)
            TextButton.icon(
              onPressed: _clearAll,
              icon: const Icon(Icons.delete_sweep, color: AppTheme.danger),
              label: const Text('Clear all', style: TextStyle(color: AppTheme.danger)),
            ),
        ],
      ),
      body: _items.isEmpty
          ? _EmptyState()
          : _CompareTable(items: _items, onRemove: _remove),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.compare_arrows, size: 80, color: Colors.black12),
          const SizedBox(height: 16),
          const Text(
            'Nothing to compare yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          const Text(
            'Run an analysis and tap "Add to Compare"\nto start building your comparison.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textLight, height: 1.5),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go back'),
          ),
        ],
      ),
    );
  }
}

// ─── Compare Table ────────────────────────────────────────────────────────────

class _CompareTable extends StatelessWidget {
  final List<CompareItem> items;
  final void Function(int) onRemove;

  const _CompareTable({required this.items, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label column
            _LabelColumn(),
            const SizedBox(width: 8),
            // One column per compared tree
            ...List.generate(items.length, (i) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _TreeColumn(
                item: items[i],
                index: i,
                onRemove: () => onRemove(i),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ─── Label Column ─────────────────────────────────────────────────────────────

class _LabelColumn extends StatelessWidget {
  static const _labels = [
    'Metric',
    '', // spacer for section header
    'Height (m)',
    'Crown Ø (m)',
    'Trunk Ø (m)',
    'Altitude (m)',
    'Zone',
    'Habitat',
    'Topography',
    'Soil',
    '', // spacer for section header
    'Food',
    'Beverage',
    'Medicine',
    'Agronomic',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderCell(text: 'Attribute', isLabel: true),
          ..._labels.skip(1).map((l) {
            if (l.isEmpty) return const _SectionDivider(isLabel: true);
            if (l == 'Food' || l == 'Beverage' || l == 'Medicine' || l == 'Agronomic') {
              return _PredLabelCell(label: l);
            }
            return _Cell(text: l, isLabel: true, isBold: true);
          }),
        ],
      ),
    );
  }
}

// ─── Tree Column ──────────────────────────────────────────────────────────────

class _TreeColumn extends StatelessWidget {
  final CompareItem item;
  final int index;
  final VoidCallback onRemove;

  const _TreeColumn({
    required this.item,
    required this.index,
    required this.onRemove,
  });

  String _fmt(double? v, {int decimals = 1}) =>
      v != null ? v.toStringAsFixed(decimals) : '—';

  String _suitability(String key) {
    final pred = item.result.predictions[key];
    if (pred == null) return '—';
    if (key == 'agronomic') {
      const labels = ['Low', 'Medium', 'High'];
      return '${labels[pred.prediction]} (${(pred.probability * 100).toStringAsFixed(0)}%)';
    }
    return '${pred.suitable == true ? '✓ Suitable' : '✗ Not Suitable'} · ${(pred.probability * 100).toStringAsFixed(0)}%';
  }

  Color _suitabilityColor(String key) {
    final pred = item.result.predictions[key];
    if (pred == null) return AppTheme.textLight;
    if (key == 'agronomic') {
      return pred.prediction == 2
          ? AppTheme.success
          : (pred.prediction == 1 ? AppTheme.accent : AppTheme.danger);
    }
    return pred.suitable == true ? AppTheme.success : AppTheme.danger;
  }

  @override
  Widget build(BuildContext context) {
    final inp = item.input;
    final colors = [AppTheme.primary, AppTheme.secondary, AppTheme.accent, AppTheme.catMedicine];
    final color = colors[index % colors.length];

    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderCell(
            text: item.label,
            isLabel: false,
            color: color,
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 16, color: Colors.white),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          // Measurements
          const _SectionDivider(isLabel: false, label: 'Measurements'),
          _Cell(text: _fmt(inp.heightM), isLabel: false),
          _Cell(text: _fmt(inp.crownDiameterM), isLabel: false),
          _Cell(text: _fmt(inp.trunkDiameterM), isLabel: false),
          _Cell(text: _fmt(inp.altitudeM, decimals: 0), isLabel: false),
          _Cell(text: inp.geographicZone ?? '—', isLabel: false),
          _Cell(text: inp.treeGrowthHabitat ?? '—', isLabel: false),
          _Cell(text: inp.topography ?? '—', isLabel: false),
          _Cell(text: inp.soilTexture ?? '—', isLabel: false),
          // Predictions
          const _SectionDivider(isLabel: false, label: 'Predictions'),
          _PredCell(text: _suitability('food'), color: _suitabilityColor('food')),
          _PredCell(text: _suitability('beverage'), color: _suitabilityColor('beverage')),
          _PredCell(text: _suitability('medicine'), color: _suitabilityColor('medicine')),
          _PredCell(text: _suitability('agronomic'), color: _suitabilityColor('agronomic')),
        ],
      ),
    );
  }
}

// ─── Cell Widgets ─────────────────────────────────────────────────────────────

class _HeaderCell extends StatelessWidget {
  final String text;
  final bool isLabel;
  final Color? color;
  final Widget? trailing;

  const _HeaderCell({required this.text, required this.isLabel, this.color, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isLabel ? AppTheme.textDark : (color ?? AppTheme.primary),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final bool isLabel;
  final bool isBold;

  const _Cell({required this.text, required this.isLabel, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isLabel ? const Color(0xFFF0EAE0) : AppTheme.card,
        border: const Border(bottom: BorderSide(color: Color(0xFFE0D6C8), width: 0.5)),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: AppTheme.textDark,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final bool isLabel;
  final String? label;

  const _SectionDivider({required this.isLabel, this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: isLabel ? const Color(0xFFD7CCC8) : const Color(0xFFEFEBE9),
      alignment: Alignment.centerLeft,
      child: Text(
        isLabel ? 'Measurements' : (label ?? ''),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.textLight,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _PredLabelCell extends StatelessWidget {
  final String label;
  const _PredLabelCell({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF0EAE0),
        border: Border(bottom: BorderSide(color: Color(0xFFE0D6C8), width: 0.5)),
      ),
      alignment: Alignment.centerLeft,
      child: Text(label,
          style: const TextStyle(fontSize: 13, color: AppTheme.textDark, fontWeight: FontWeight.w600)),
    );
  }
}

class _PredCell extends StatelessWidget {
  final String text;
  final Color color;
  const _PredCell({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        border: const Border(bottom: BorderSide(color: Color(0xFFE0D6C8), width: 0.5)),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
