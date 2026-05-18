import '../models/scan_result.dart';

/// In-memory scan history with a configurable capacity.
class HistoryService {
  final int maxItems;
  final List<SmartScanResult> _history = [];

  HistoryService({this.maxItems = 50});

  List<SmartScanResult> get items => List.unmodifiable(_history);

  int get count => _history.length;

  bool get isEmpty => _history.isEmpty;

  void add(SmartScanResult result) {
    if (!result.isSuccess) return;
    _history.insert(0, result);
    if (_history.length > maxItems) _history.removeLast();
  }

  void remove(SmartScanResult result) => _history.remove(result);

  void clear() => _history.clear();

  bool contains(String rawValue) =>
      _history.any((r) => r.rawValue == rawValue);
}
