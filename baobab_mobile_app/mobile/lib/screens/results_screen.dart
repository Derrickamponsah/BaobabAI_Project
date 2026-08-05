import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class ResultsScreen extends StatelessWidget {
  final BaobabInput input;
  final PredictionResult result;
  const ResultsScreen({super.key, required this.input, required this.result});

  @override
  Widget build(BuildContext context) {
    final p = result.predictions;

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
          ...result.recommendations.map((r) => _RecommendationAlert(r)),

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
                  onPressed: () {}, // visual placeholder for export
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
                  onPressed: () {}, // visual placeholder for compare
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
      builder: (_) => _FeedbackSheet(input: input, result: result),
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

class _ProbabilityChart extends StatelessWidget {
  final Map<String, TaskPrediction> predictions;
  const _ProbabilityChart({required this.predictions});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (predictions['food'] != null)
            _Bar(label: 'Food', prob: predictions['food']!.probability, color: AppTheme.catFood),
          if (predictions['beverage'] != null)
            _Bar(label: 'Bev', prob: predictions['beverage']!.probability, color: AppTheme.catBeverage),
          if (predictions['medicine'] != null)
            _Bar(label: 'Med', prob: predictions['medicine']!.probability, color: AppTheme.catMedicine),
          if (predictions['agronomic'] != null)
            _Bar(label: 'Agro', prob: predictions['agronomic']!.probability, color: AppTheme.catAgronomic),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final double prob;
  final Color color;
  const _Bar({required this.label, required this.prob, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('${(prob * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 120 * prob,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
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
