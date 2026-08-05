import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.instance.history();
  }

  String _fmt(String iso) {
    try {
      return DateFormat('d MMM yyyy, HH:mm').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 56, color: Colors.black26),
                  SizedBox(height: 10),
                  Text('No predictions yet',
                      style: TextStyle(color: Colors.black54)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final rec = items[i] as Map<String, dynamic>;
              final preds = (rec['result']?['predictions'] ?? {}) as Map;
              final agro = preds['agronomic']?['prediction'];
              final chips = <Widget>[];
              void add(String k, String label) {
                if (preds[k]?['suitable'] == true) {
                  chips.add(_tag(label, AppTheme.secondary));
                }
              }
              add('food', 'Food');
              add('beverage', 'Beverage');
              add('medicine', 'Medicine');
              if (agro != null) {
                chips.add(_tag(
                    'Agro: ${['Low', 'Med', 'High'][agro]}', AppTheme.accent));
              }
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                              rec['source'] == 'image'
                                  ? Icons.photo_camera_outlined
                                  : Icons.edit_note,
                              size: 18,
                              color: Colors.black45),
                          const SizedBox(width: 6),
                          Text(_fmt(rec['created_at'] ?? ''),
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 6, children: chips),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _tag(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 12)),
      );
}
