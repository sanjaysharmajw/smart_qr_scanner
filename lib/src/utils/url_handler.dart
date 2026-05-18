import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/scan_result.dart';

/// Launches the appropriate system app for a scan result's content type.
class SmartUrlHandler {
  SmartUrlHandler._();

  /// Returns true if [result] can be launched (URL, email, phone, SMS, geo).
  static bool canHandle(SmartScanResult result) {
    switch (result.type) {
      case BarcodeType.url:
      case BarcodeType.email:
      case BarcodeType.phone:
      case BarcodeType.sms:
      case BarcodeType.geoCoordinates:
        return true;
      default:
        return result.rawValue.startsWith('http://') ||
            result.rawValue.startsWith('https://');
    }
  }

  /// Launches the best system handler for [result].
  /// Returns false if no handler is found or launch fails.
  static Future<bool> launch(SmartScanResult result) async {
    final uri = _buildUri(result);
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static Uri? _buildUri(SmartScanResult result) {
    final raw = result.rawValue;
    switch (result.type) {
      case BarcodeType.url:
        return Uri.tryParse(raw);
      case BarcodeType.email:
        final email = raw.startsWith('mailto:') ? raw : 'mailto:$raw';
        return Uri.tryParse(email);
      case BarcodeType.phone:
        final phone = raw.startsWith('tel:') ? raw : 'tel:$raw';
        return Uri.tryParse(phone);
      case BarcodeType.sms:
        final sms = raw.startsWith('sms:') ? raw : 'sms:$raw';
        return Uri.tryParse(sms);
      case BarcodeType.geoCoordinates:
        final geo = raw.replaceFirst('geo:', '');
        return Uri.tryParse('geo:$geo');
      default:
        if (raw.startsWith('http://') || raw.startsWith('https://')) {
          return Uri.tryParse(raw);
        }
        return null;
    }
  }

  /// Human-readable action label for the launch button.
  static String actionLabel(SmartScanResult result) {
    switch (result.type) {
      case BarcodeType.url:
        return 'Open URL';
      case BarcodeType.email:
        return 'Send Email';
      case BarcodeType.phone:
        return 'Call';
      case BarcodeType.sms:
        return 'Send SMS';
      case BarcodeType.geoCoordinates:
        return 'Open Map';
      default:
        return 'Open';
    }
  }
}
