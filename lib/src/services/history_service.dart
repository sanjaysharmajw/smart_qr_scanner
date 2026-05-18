import '../models/scan_result.dart';
import 'storage_service.dart';

/// In-memory scan history with a configurable capacity.
/// Persists automatically via [StorageService].
class HistoryService {
  final int maxItems;
  final List<SmartScanResult> _history = [];

  HistoryService({this.maxItems = 50});

  List<SmartScanResult> get items => List.unmodifiable(_history);
  int get count => _history.length;
  bool get isEmpty => _history.isEmpty;

  Future<void> load() async {
    final saved = await StorageService.loadHistory();
    _history
      ..clear()
      ..addAll(saved.take(maxItems));
  }

  void add(SmartScanResult result) {
    if (!result.isSuccess) return;
    _history.insert(0, result);
    if (_history.length > maxItems) _history.removeLast();
    StorageService.saveHistory(_history);
  }

  void remove(SmartScanResult result) {
    _history.remove(result);
    StorageService.saveHistory(_history);
  }

  void clear() {
    _history.clear();
    StorageService.clearHistory();
  }

  bool contains(String rawValue) =>
      _history.any((r) => r.rawValue == rawValue);
}
