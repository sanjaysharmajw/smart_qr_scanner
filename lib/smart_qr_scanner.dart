/// smart_qr_scanner — Production-ready QR & barcode scanner for Flutter.
///
/// Quick start:
/// ```dart
/// final controller = SmartQrScannerController(config: ScannerConfig());
/// await controller.initialize();
///
/// SmartScannerWidget(
///   controller: controller,
///   theme: ScannerTheme.neon,
/// )
/// ```
library smart_qr_scanner;

// Re-export ML Kit types so consumers don't need to add
// google_mlkit_barcode_scanning to their own pubspec.
export 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
    show BarcodeFormat, BarcodeType, Barcode;

export 'src/controllers/scanner_controller.dart';
export 'src/engine/scanner_engine.dart';
export 'src/models/scan_result.dart';
export 'src/models/scanner_config.dart';
export 'src/models/scanner_theme.dart';
export 'src/services/favorites_service.dart';
export 'src/services/feedback_service.dart';
export 'src/services/history_exporter.dart';
export 'src/services/history_service.dart';
export 'src/services/permission_service.dart';
export 'src/services/storage_service.dart';
export 'src/ui/components/duplicate_toast.dart';
export 'src/ui/components/favorite_button.dart';
export 'src/ui/components/pixel_burst_animation.dart';
export 'src/ui/components/scan_controls.dart';
export 'src/ui/components/scan_hint_widget.dart';
export 'src/ui/components/scan_success_animation.dart';
export 'src/ui/painters/bounding_box_painter.dart';
export 'src/ui/painters/scanner_overlay_painter.dart';
export 'src/ui/qr_generator_widget.dart';
export 'src/ui/smart_scanner_widget.dart';
export 'src/utils/barcode_utils.dart';
export 'src/utils/url_handler.dart';
