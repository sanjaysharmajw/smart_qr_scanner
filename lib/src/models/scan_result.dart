import 'dart:math' show Point;
import 'dart:ui' show Offset, Rect;
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

/// The outcome category of a scan attempt.
enum ScanResultType { success, duplicate, error, timeout }

BarcodeFormat _formatFromIndex(int index) {
  const values = BarcodeFormat.values;
  return index >= 0 && index < values.length ? values[index] : BarcodeFormat.unknown;
}

BarcodeType _typeFromIndex(int index) {
  const values = BarcodeType.values;
  return index >= 0 && index < values.length ? values[index] : BarcodeType.unknown;
}

/// Immutable representation of a single scan event.
@immutable
class SmartScanResult {
  final String rawValue;
  final String? displayValue;
  final BarcodeFormat format;
  final BarcodeType type;
  final DateTime timestamp;
  final ScanResultType resultType;
  final Rect? boundingBox;
  final List<Offset>? cornerPoints;
  final double? confidence;
  final Map<String, dynamic> metadata;

  const SmartScanResult({
    required this.rawValue,
    required this.format,
    required this.type,
    required this.timestamp,
    required this.resultType,
    this.displayValue,
    this.boundingBox,
    this.cornerPoints,
    this.confidence,
    this.metadata = const {},
  });

  factory SmartScanResult.fromBarcode(Barcode barcode) => SmartScanResult(
        rawValue: barcode.rawValue ?? '',
        displayValue: barcode.displayValue,
        format: barcode.format,
        type: barcode.type,
        timestamp: DateTime.now(),
        resultType: ScanResultType.success,
        boundingBox: barcode.boundingBox,
        cornerPoints: barcode.cornerPoints
            .whereType<Point<int>>()
            .map((p) => Offset(p.x.toDouble(), p.y.toDouble()))
            .toList(),
        metadata: _extractMetadata(barcode),
      );

  factory SmartScanResult.duplicate(String rawValue) => SmartScanResult(
        rawValue: rawValue,
        format: BarcodeFormat.unknown,
        type: BarcodeType.unknown,
        timestamp: DateTime.now(),
        resultType: ScanResultType.duplicate,
      );

  factory SmartScanResult.error(String message) => SmartScanResult(
        rawValue: message,
        format: BarcodeFormat.unknown,
        type: BarcodeType.unknown,
        timestamp: DateTime.now(),
        resultType: ScanResultType.error,
      );

  factory SmartScanResult.timeout() => SmartScanResult(
        rawValue: 'Scan timed out',
        format: BarcodeFormat.unknown,
        type: BarcodeType.unknown,
        timestamp: DateTime.now(),
        resultType: ScanResultType.timeout,
      );

  // ML Kit 0.13.x exposes only rawValue/displayValue at the Barcode level.
  // Structured fields (email, url, wifi…) live in the raw string; apps that
  // need them should parse rawValue according to the detected BarcodeType.
  static Map<String, dynamic> _extractMetadata(Barcode barcode) {
    final m = <String, dynamic>{};
    if (barcode.displayValue != null) m['display'] = barcode.displayValue;
    // Type-specific parsing based on rawValue
    final raw = barcode.rawValue ?? '';
    switch (barcode.type) {
      case BarcodeType.url:
        m['url'] = raw;
      case BarcodeType.email:
        m['email'] = raw.replaceFirst('mailto:', '');
      case BarcodeType.phone:
        m['phone'] = raw.replaceFirst('tel:', '');
      case BarcodeType.wifi:
        // WIFI:T:WPA;S:ssid;P:pass;;
        final ssid = RegExp(r'S:([^;]+)').firstMatch(raw)?.group(1);
        final pass = RegExp(r'P:([^;]+)').firstMatch(raw)?.group(1);
        if (ssid != null) m['wifi_ssid'] = ssid;
        if (pass != null) m['wifi_password'] = pass;
      case BarcodeType.geoCoordinates:
        // geo:lat,lng
        final geo = raw.replaceFirst('geo:', '').split(',');
        if (geo.length >= 2) {
          m['latitude'] = geo[0];
          m['longitude'] = geo[1];
        }
      default:
        break;
    }
    return m;
  }

  String get formatName {
    switch (format) {
      case BarcodeFormat.qrCode:    return 'QR Code';
      case BarcodeFormat.aztec:     return 'Aztec';
      case BarcodeFormat.codabar:   return 'Codabar';
      case BarcodeFormat.code39:    return 'Code 39';
      case BarcodeFormat.code93:    return 'Code 93';
      case BarcodeFormat.code128:   return 'Code 128';
      case BarcodeFormat.dataMatrix:return 'Data Matrix';
      case BarcodeFormat.ean8:      return 'EAN-8';
      case BarcodeFormat.ean13:     return 'EAN-13';
      case BarcodeFormat.itf:       return 'ITF';
      case BarcodeFormat.pdf417:    return 'PDF417';
      case BarcodeFormat.upca:      return 'UPC-A';
      case BarcodeFormat.upce:      return 'UPC-E';
      default:                      return 'Unknown';
    }
  }

  String get typeName {
    switch (type) {
      case BarcodeType.url:           return 'URL';
      case BarcodeType.email:         return 'Email';
      case BarcodeType.phone:         return 'Phone';
      case BarcodeType.sms:           return 'SMS';
      case BarcodeType.wifi:          return 'WiFi';
      case BarcodeType.geoCoordinates:return 'Location';
      case BarcodeType.contactInfo:   return 'Contact';
      case BarcodeType.calendarEvent: return 'Calendar';
      case BarcodeType.driverLicense: return 'Driver License';
      case BarcodeType.text:          return 'Text';
      case BarcodeType.isbn:          return 'ISBN';
      case BarcodeType.product:       return 'Product';
      default:                        return 'Unknown';
    }
  }

  bool get isSuccess => resultType == ScanResultType.success;
  bool get isEmpty => rawValue.isEmpty;

  SmartScanResult copyWith({
    String? rawValue,
    String? displayValue,
    BarcodeFormat? format,
    BarcodeType? type,
    DateTime? timestamp,
    ScanResultType? resultType,
    Rect? boundingBox,
    List<Offset>? cornerPoints,
    double? confidence,
    Map<String, dynamic>? metadata,
  }) =>
      SmartScanResult(
        rawValue: rawValue ?? this.rawValue,
        displayValue: displayValue ?? this.displayValue,
        format: format ?? this.format,
        type: type ?? this.type,
        timestamp: timestamp ?? this.timestamp,
        resultType: resultType ?? this.resultType,
        boundingBox: boundingBox ?? this.boundingBox,
        cornerPoints: cornerPoints ?? this.cornerPoints,
        confidence: confidence ?? this.confidence,
        metadata: metadata ?? this.metadata,
      );

  Map<String, dynamic> toJson() => {
        'rawValue': rawValue,
        if (displayValue != null) 'displayValue': displayValue,
        'format': format.index,
        'type': type.index,
        'timestamp': timestamp.toIso8601String(),
        'resultType': resultType.name,
        if (confidence != null) 'confidence': confidence,
        if (boundingBox != null)
          'boundingBox': {
            'l': boundingBox!.left,
            't': boundingBox!.top,
            'r': boundingBox!.right,
            'b': boundingBox!.bottom,
          },
        if (cornerPoints != null)
          'cornerPoints': cornerPoints!
              .map((o) => {'x': o.dx, 'y': o.dy})
              .toList(),
        'metadata': metadata,
      };

  factory SmartScanResult.fromJson(Map<String, dynamic> json) {
    Rect? bbox;
    final bj = json['boundingBox'];
    if (bj is Map) {
      bbox = Rect.fromLTRB(
        (bj['l'] as num).toDouble(),
        (bj['t'] as num).toDouble(),
        (bj['r'] as num).toDouble(),
        (bj['b'] as num).toDouble(),
      );
    }

    List<Offset>? corners;
    final cj = json['cornerPoints'];
    if (cj is List) {
      corners = cj
          .cast<Map<String, dynamic>>()
          .map((p) => Offset(
                (p['x'] as num).toDouble(),
                (p['y'] as num).toDouble(),
              ))
          .toList();
    }

    return SmartScanResult(
      rawValue: json['rawValue'] as String,
      displayValue: json['displayValue'] as String?,
      format: _formatFromIndex(json['format'] as int? ?? 0),
      type: _typeFromIndex(json['type'] as int? ?? 0),
      timestamp: DateTime.parse(json['timestamp'] as String),
      resultType: ScanResultType.values.firstWhere(
        (r) => r.name == json['resultType'],
        orElse: () => ScanResultType.success,
      ),
      confidence: (json['confidence'] as num?)?.toDouble(),
      boundingBox: bbox,
      cornerPoints: corners,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmartScanResult &&
          other.rawValue == rawValue &&
          other.timestamp == timestamp &&
          other.resultType == resultType;

  @override
  int get hashCode => Object.hash(rawValue, timestamp, resultType);

  @override
  String toString() => 'SmartScanResult($formatName: $rawValue)';
}
