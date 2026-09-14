import '../models/models.dart';

/// Holds a single item in the comparison list.
class CompareItem {
  final BaobabInput input;
  final PredictionResult result;
  final DateTime addedAt;
  final String label;

  CompareItem({
    required this.input,
    required this.result,
    required this.label,
  }) : addedAt = DateTime.now();
}

/// Singleton service that stores trees added for comparison.
class CompareService {
  CompareService._();
  static final instance = CompareService._();

  final List<CompareItem> _items = [];

  List<CompareItem> get items => List.unmodifiable(_items);

  int get count => _items.length;

  /// Adds a tree to the compare list (max 4). Returns an error message if full.
  String? addItem(BaobabInput input, PredictionResult result) {
    if (_items.length >= 4) {
      return 'Compare list is full (max 4 trees). Remove one first.';
    }
    _items.add(CompareItem(
      input: input,
      result: result,
      label: 'Tree ${_items.length + 1}',
    ));
    return null;
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      // Re-label remaining items
      for (int i = 0; i < _items.length; i++) {
        // Labels are immutable, so we just leave them as-is.
      }
    }
  }

  void clear() => _items.clear();
}
