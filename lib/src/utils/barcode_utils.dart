import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

/// Utility helpers for barcode data validation and formatting.
class BarcodeUtils {
  BarcodeUtils._();

  /// Returns true when [value] looks like a valid HTTP/HTTPS URL.
  static bool isUrl(String value) {
    try {
      final uri = Uri.parse(value);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }

  /// Returns true when [value] looks like an email address.
  static bool isEmail(String value) => RegExp(
        r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
      ).hasMatch(value);

  /// Returns true when [value] looks like a phone number.
  static bool isPhone(String value) =>
      RegExp(r'^\+?[0-9\s\-().]{7,20}$').hasMatch(value);

  /// Returns true when [value] appears to be a WiFi QR payload.
  static bool isWifi(String value) => value.startsWith('WIFI:');

  /// Sanitises and trims a raw barcode value.
  static String sanitize(String raw) => raw.trim();

  /// Returns false for obviously malformed / empty values.
  static bool isValid(String raw) => raw.trim().isNotEmpty && raw.length < 4096;

  /// Human-readable label for a [BarcodeFormat].
  static String formatLabel(BarcodeFormat format) {
    const labels = <BarcodeFormat, String>{
      BarcodeFormat.qrCode: 'QR Code',
      BarcodeFormat.aztec: 'Aztec',
      BarcodeFormat.codabar: 'Codabar',
      BarcodeFormat.code39: 'Code 39',
      BarcodeFormat.code93: 'Code 93',
      BarcodeFormat.code128: 'Code 128',
      BarcodeFormat.dataMatrix: 'Data Matrix',
      BarcodeFormat.ean8: 'EAN-8',
      BarcodeFormat.ean13: 'EAN-13',
      BarcodeFormat.itf: 'ITF',
      BarcodeFormat.pdf417: 'PDF417',
      BarcodeFormat.upca: 'UPC-A',
      BarcodeFormat.upce: 'UPC-E',
    };
    return labels[format] ?? 'Unknown';
  }

  /// Returns an appropriate icon label (Material icon name hint) for a type.
  static String typeIconHint(BarcodeType type) {
    switch (type) {
      case BarcodeType.url:           return 'link';
      case BarcodeType.email:         return 'email';
      case BarcodeType.phone:         return 'phone';
      case BarcodeType.sms:           return 'message';
      case BarcodeType.wifi:          return 'wifi';
      case BarcodeType.geoCoordinates:return 'location_on';
      case BarcodeType.contactInfo:   return 'contact_page';
      case BarcodeType.calendarEvent: return 'event';
      default:                        return 'qr_code';
    }
  }
}
