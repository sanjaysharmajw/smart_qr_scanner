import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/scan_result.dart';

/// Exports scan history as a CSV file saved to the temporary directory.
class HistoryExporter {
  HistoryExporter._();

  static const _header = 'Timestamp,Format,Type,Raw Value,Display Value,Confidence\n';

  /// Writes [items] as a CSV file to the temp directory.
  /// Returns false if the list is empty.
  static Future<bool> exportCsv(List<SmartScanResult> items) async {
    if (items.isEmpty) return false;

    final buf = StringBuffer(_header);
    for (final r in items) {
      buf.write([
        _escape(r.timestamp.toIso8601String()),
        _escape(r.formatName),
        _escape(r.typeName),
        _escape(r.rawValue),
        _escape(r.displayValue ?? ''),
        _escape(r.confidence?.toStringAsFixed(2) ?? ''),
      ].join(','));
      buf.write('\n');
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/scan_history.csv');
    await file.writeAsString(buf.toString());
    return true;
  }

  static String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
