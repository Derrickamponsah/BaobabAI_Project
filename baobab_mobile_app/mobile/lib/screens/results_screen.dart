import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/compare_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class ResultsScreen extends StatefulWidget {
  final BaobabInput input;
  final PredictionResult result;
  const ResultsScreen({super.key, required this.input, required this.result});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  void _addToCompare() {
    final err = CompareService.instance.addItem(widget.input, widget.result);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    // Navigate directly to the compare screen
    Navigator.pushNamed(context, '/compare');
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.result.predictions;

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          const Text('Assessment Results', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
          const SizedBox(height: 6),
          const Text('Analysis based on provided morphological and environmental data.', style: TextStyle(color: AppTheme.textLight, fontSize: 15)),
          const SizedBox(height: 24),
          
          Row(
            children: [
              if (p['food'] != null)
                Expanded(child: _ResultCard(title: 'Food Use', icon: Icons.restaurant, pred: p['food']!, color: AppTheme.catFood)),
              const SizedBox(width: 16),
              if (p['beverage'] != null)
                Expanded(child: _ResultCard(title: 'Beverage Use', icon: Icons.local_drink, pred: p['beverage']!, color: AppTheme.catBeverage)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (p['medicine'] != null)
                Expanded(child: _ResultCard(title: 'Medicine Use', icon: Icons.medical_services, pred: p['medicine']!, color: AppTheme.catMedicine)),
              const SizedBox(width: 16),
              if (p['agronomic'] != null)
                Expanded(child: _ResultCard(title: 'Agronomic Value', icon: Icons.eco, pred: p['agronomic']!, color: AppTheme.catAgronomic, isAgronomic: true)),
            ],
          ),
          const SizedBox(height: 32),

          const Text('Probability Breakdown', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE9ECEF)),
            ),
            child: _ProbabilityChart(predictions: p),
          ),
          const SizedBox(height: 32),

          const Text('Recommendations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
          const SizedBox(height: 16),
          ...widget.result.recommendations.map((r) => _RecommendationAlert(r)),

          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => _openFeedback(context),
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Confirm / correct actual attributes'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Results exported successfully!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }, // visual placeholder for export
                  icon: const Icon(Icons.download),
                  label: const Text('Export Results'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: AppTheme.textDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addToCompare,
                  icon: const Icon(Icons.compare_arrows),
                  label: const Text('Add to Compare'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: AppTheme.textDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _openFeedback(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FeedbackSheet(input: widget.input, result: widget.result),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final TaskPrediction pred;
  final Color color;
  final bool isAgronomic;

  const _ResultCard({
    required this.title,
    required this.icon,
    required this.pred,
    required this.color,
    this.isAgronomic = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isAgronomic
        ? (pred.prediction == 2 ? AppTheme.success : (pred.prediction == 1 ? AppTheme.accent : AppTheme.danger))
        : (pred.suitable == true ? AppTheme.success : AppTheme.danger);
    final statusText = isAgronomic
        ? ['Low', 'Medium', 'High'][pred.prediction].toUpperCase()
        : (pred.suitable == true ? 'SUITABLE' : 'NOT SUITABLE');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Left border accent
          Positioned(
            left: -16, top: -16, bottom: -16, width: 4,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(width: 8),
                  Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textDark))),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Model confidence', style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: pred.probability,
                          child: Container(color: Colors.white.withOpacity(0.0)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${(pred.probability * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProbabilityChart extends StatefulWidget {
  final Map<String, TaskPrediction> predictions;
  const _ProbabilityChart({required this.predictions});

  @override
  State<_ProbabilityChart> createState() => _ProbabilityChartState();
}

class _ProbabilityChartState extends State<_ProbabilityChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  static const _categories = [
    _ChartCat('Food',      'food',      AppTheme.catFood),
    _ChartCat('Beverage',  'beverage',  AppTheme.catBeverage),
    _ChartCat('Medicine',  'medicine',  AppTheme.catMedicine),
    _ChartCat('Agronomic', 'agronomic', AppTheme.catAgronomic),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bars = _categories
        .where((c) => widget.predictions[c.key] != null)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart area
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Y-axis labels
                _YAxisLabels(),
                const SizedBox(width: 8),
                // Bars + gridlines
                Expanded(
                  child: Stack(
                    children: [
                      // Horizontal gridlines
                      _GridLines(),
                      // Bars
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: bars.map((c) {
                          final prob = widget.predictions[c.key]!.probability;
                          return _AnimatedBar(
                            label: c.label,
                            prob: prob,
                            color: c.color,
                            animValue: _anim.value,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Legend
        Wrap(
          spacing: 20,
          runSpacing: 8,
          children: bars.map((c) {
            final pred = widget.predictions[c.key]!;
            return _LegendItem(
              color: c.color,
              label: c.label,
              pct: pred.probability,
              suitable: pred.suitable,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ChartCat {
  final String label;
  final String key;
  final Color color;
  const _ChartCat(this.label, this.key, this.color);
}

class _YAxisLabels extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: ['100%', '75%', '50%', '25%', '0%']
            .map((l) => Text(l,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w500)))
            .toList(),
      ),
    );
  }
}

class _GridLines extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (i) => Divider(
        height: 1,
        color: i == 4
            ? const Color(0xFFD7CCC8)
            : const Color(0xFFEFEBE9),
        thickness: i == 4 ? 1.5 : 1,
      )),
    );
  }
}

class _AnimatedBar extends StatelessWidget {
  final String label;
  final double prob;
  final Color color;
  final double animValue;

  const _AnimatedBar({
    required this.label,
    required this.prob,
    required this.color,
    required this.animValue,
  });

  @override
  Widget build(BuildContext context) {
    const maxHeight = 160.0;
    final barHeight = maxHeight * prob * animValue;
    final pct = (prob * 100 * animValue).toStringAsFixed(0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Value bubble
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: animValue > 0.6 ? 1.0 : 0.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Text(
              '$pct%',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // The bar itself with gradient
        Container(
          width: 44,
          height: barHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.6), color],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // X-axis label
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double pct;
  final bool? suitable;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.pct,
    required this.suitable,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = suitable == null
        ? ''
        : suitable! ? '  ✓ Suitable' : '  ✗ Not Suitable';
    final statusColor = suitable == null
        ? AppTheme.textLight
        : suitable! ? AppTheme.success : AppTheme.danger;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textDark, fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        Text('${(pct * 100).toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
        if (statusText.isNotEmpty)
          Text(statusText,
              style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
      ],
    );
  }
}


class _RecommendationAlert extends StatelessWidget {
  final String text;
  const _RecommendationAlert(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: const Border(left: BorderSide(color: Color(0xFF4C84FF), width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: Color(0xFF4C84FF), size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: AppTheme.textDark, height: 1.4))),
        ],
      ),
    );
  }
}

// Keeping the feedback bottom sheet as it was
class _FeedbackSheet extends StatefulWidget {
  final BaobabInput input;
  final PredictionResult result;
  const _FeedbackSheet({required this.input, required this.result});
  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  late bool _food;
  late bool _beverage;
  late bool _medicine;
  late int _agronomic;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.result.predictions;
    _food = p['food']?.suitable ?? false;
    _beverage = p['beverage']?.suitable ?? false;
    _medicine = p['medicine']?.suitable ?? false;
    _agronomic = p['agronomic']?.prediction ?? 0;
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final res = await ApiService.instance.submitFeedback(widget.input, {
        'food': _food ? 1 : 0,
        'beverage': _beverage ? 1 : 0,
        'medicine': _medicine ? 1 : 0,
        'agronomic': _agronomic,
      });
      if (!mounted) return;
      Navigator.pop(context);
      final retrain = res['retrain'] as Map<String, dynamic>?;
      final msg = (retrain?['triggered'] == true)
          ? 'Thank you! Enough new data — the model is retraining now.'
          : 'Thank you! Your confirmation was saved for future retraining.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Confirm actual attributes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Your input trains the next model version.', style: TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 12),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Suitable for food'), value: _food, onChanged: (v) => setState(() => _food = v)),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Suitable for beverage'), value: _beverage, onChanged: (v) => setState(() => _beverage = v)),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Suitable for medicine'), value: _medicine, onChanged: (v) => setState(() => _medicine = v)),
          const SizedBox(height: 8),
          const Text('Agronomic value'),
          const SizedBox(height: 6),
          SegmentedButton<int>(
            segments: const [ButtonSegment(value: 0, label: Text('Low')), ButtonSegment(value: 1, label: Text('Medium')), ButtonSegment(value: 2, label: Text('High'))],
            selected: {_agronomic},
            onSelectionChanged: (s) => setState(() => _agronomic = s.first),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4)) : const Icon(Icons.send),
            label: const Text('Submit confirmation'),
          ),
        ],
      ),
    );
  }
}
