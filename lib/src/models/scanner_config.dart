import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

/// Camera lens direction preference.
enum CameraFacing { front, back }

/// Whether to stop after first result or keep scanning.
enum ScanMode { single, continuous }

/// All supported barcode formats exposed as a convenience list.
const List<BarcodeFormat> kAllBarcodeFormats = [
  BarcodeFormat.qrCode,
  BarcodeFormat.aztec,
  BarcodeFormat.codabar,
  BarcodeFormat.code39,
  BarcodeFormat.code93,
  BarcodeFormat.code128,
  BarcodeFormat.dataMatrix,
  BarcodeFormat.ean8,
  BarcodeFormat.ean13,
  BarcodeFormat.itf,
  BarcodeFormat.pdf417,
  BarcodeFormat.upca,
  BarcodeFormat.upce,
];

/// Configuration object passed to [SmartQrScannerController].
/// All fields are immutable; use [copyWith] to derive variants.
@immutable
class ScannerConfig {
  /// Scan one code then stop, or keep scanning until [pause]/[stop] is called.
  final ScanMode scanMode;

  /// Which camera to open first.
  final CameraFacing cameraFacing;

  /// Restrict which barcode formats are recognised. Empty = all formats.
  final List<BarcodeFormat> formats;

  /// Start with torch/flash on.
  final bool enableFlash;

  /// Trigger haptic vibration on successful scan.
  final bool enableVibration;

  /// Play a beep sound on successful scan.
  final bool enableSound;

  /// Pass auto-focus hint to camera.
  final bool enableAutoFocus;

  /// Attempt software zoom to fill scan area.
  final bool enableAutoZoom;

  /// Suppress identical results within [duplicatePreventionWindow].
  final bool preventDuplicates;

  /// How long to ignore a repeated value after a successful scan.
  final Duration duplicatePreventionWindow;

  /// Emit a timeout result if nothing is scanned within this duration.
  /// Null = no timeout.
  final Duration? scanTimeout;

  /// Draw animated bounding box around detected codes.
  final bool enableBoundingBox;

  /// Keep a local history of scans in memory.
  final bool enableScanHistory;

  /// Maximum number of results kept in history.
  final int maxHistoryItems;

  /// Scan-area width as a fraction of screen width [0.0 – 1.0].
  final double scanAreaWidthFactor;

  /// Scan-area height as a fraction of screen height [0.0 – 1.0].
  final double scanAreaHeightFactor;

  /// Enable low-light camera exposure tuning.
  final bool enableLowLightOptimization;

  /// Process every Nth frame; 0 means process every frame.
  final int framesToSkip;

  /// Optional callback invoked on every scan event (analytics hook).
  final void Function(String rawValue, String format)? onAnalyticsEvent;

  const ScannerConfig({
    this.scanMode = ScanMode.single,
    this.cameraFacing = CameraFacing.back,
    this.formats = const [],
    this.enableFlash = false,
    this.enableVibration = true,
    this.enableSound = true,
    this.enableAutoFocus = true,
    this.enableAutoZoom = false,
    this.preventDuplicates = true,
    this.duplicatePreventionWindow = const Duration(seconds: 2),
    this.scanTimeout,
    this.enableBoundingBox = true,
    this.enableScanHistory = true,
    this.maxHistoryItems = 50,
    this.scanAreaWidthFactor = 0.75,
    this.scanAreaHeightFactor = 0.35,
    this.enableLowLightOptimization = true,
    this.framesToSkip = 0,
    this.onAnalyticsEvent,
  });

  /// Returns the effective list of [BarcodeFormat]s sent to ML Kit.
  List<BarcodeFormat> get effectiveFormats =>
      formats.isEmpty ? kAllBarcodeFormats : formats;

  ScannerConfig copyWith({
    ScanMode? scanMode,
    CameraFacing? cameraFacing,
    List<BarcodeFormat>? formats,
    bool? enableFlash,
    bool? enableVibration,
    bool? enableSound,
    bool? enableAutoFocus,
    bool? enableAutoZoom,
    bool? preventDuplicates,
    Duration? duplicatePreventionWindow,
    Duration? scanTimeout,
    bool? enableBoundingBox,
    bool? enableScanHistory,
    int? maxHistoryItems,
    double? scanAreaWidthFactor,
    double? scanAreaHeightFactor,
    bool? enableLowLightOptimization,
    int? framesToSkip,
    void Function(String, String)? onAnalyticsEvent,
  }) =>
      ScannerConfig(
        scanMode: scanMode ?? this.scanMode,
        cameraFacing: cameraFacing ?? this.cameraFacing,
        formats: formats ?? this.formats,
        enableFlash: enableFlash ?? this.enableFlash,
        enableVibration: enableVibration ?? this.enableVibration,
        enableSound: enableSound ?? this.enableSound,
        enableAutoFocus: enableAutoFocus ?? this.enableAutoFocus,
        enableAutoZoom: enableAutoZoom ?? this.enableAutoZoom,
        preventDuplicates: preventDuplicates ?? this.preventDuplicates,
        duplicatePreventionWindow:
            duplicatePreventionWindow ?? this.duplicatePreventionWindow,
        scanTimeout: scanTimeout ?? this.scanTimeout,
        enableBoundingBox: enableBoundingBox ?? this.enableBoundingBox,
        enableScanHistory: enableScanHistory ?? this.enableScanHistory,
        maxHistoryItems: maxHistoryItems ?? this.maxHistoryItems,
        scanAreaWidthFactor: scanAreaWidthFactor ?? this.scanAreaWidthFactor,
        scanAreaHeightFactor:
            scanAreaHeightFactor ?? this.scanAreaHeightFactor,
        enableLowLightOptimization:
            enableLowLightOptimization ?? this.enableLowLightOptimization,
        framesToSkip: framesToSkip ?? this.framesToSkip,
        onAnalyticsEvent: onAnalyticsEvent ?? this.onAnalyticsEvent,
      );
}
