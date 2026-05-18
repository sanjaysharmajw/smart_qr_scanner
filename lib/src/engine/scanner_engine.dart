import 'dart:async';
import 'dart:ui' show Rect, Size;

import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import '../models/scan_result.dart';
import '../models/scanner_config.dart';
import '../utils/barcode_utils.dart';
import '../utils/image_utils.dart';
import '../utils/throttle_utils.dart';

/// Low-level scanning engine that wraps [BarcodeScanner] and the camera stream.
///
/// It owns the [CameraController], manages frame processing, and emits
/// [SmartScanResult]s through [resultStream]. Higher-level state (history,
/// duplicate prevention, timeouts) is handled by [SmartQrScannerController].
class ScannerEngine {
  final ScannerConfig config;

  // Mutable: toggled by switchCamera independent of immutable config.
  late CameraFacing _currentFacing;

  ScannerEngine(this.config) : _currentFacing = config.cameraFacing;

  late CameraController _cameraController;
  late BarcodeScanner _barcodeScanner;
  late FrameThrottle _throttle;

  final _resultController = StreamController<List<SmartScanResult>>.broadcast();
  Stream<List<SmartScanResult>> get resultStream => _resultController.stream;

  bool _isProcessing = false;
  bool _isPaused = false;
  bool _isDisposed = false;
  int _frameCount = 0;

  CameraController get cameraController => _cameraController;
  bool get isPaused => _isPaused;
  CameraFacing get currentFacing => _currentFacing;

  /// Initialises the camera and the ML Kit barcode scanner.
  /// Throws a [ScannerException] on failure.
  Future<void> init(List<CameraDescription> cameras) async {
    await _initWithFacing(cameras, _currentFacing);
  }

  Future<void> _initWithFacing(
      List<CameraDescription> cameras, CameraFacing facing) async {
    final lens = facing == CameraFacing.back
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == lens,
      orElse: () => cameras.first,
    );

    _barcodeScanner = BarcodeScanner(formats: config.effectiveFormats);
    _throttle = FrameThrottle(duration: const Duration(milliseconds: 80));

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _cameraController.initialize();
    } catch (e) {
      throw ScannerException('Camera init failed: $e');
    }

    await _loadZoomLimits();

    if (config.enableAutoFocus) {
      await _cameraController.setFocusMode(FocusMode.auto).catchError((_) {});
    }

    // Flash is only supported on the back camera.
    if (config.enableFlash && facing == CameraFacing.back) {
      await _cameraController
          .setFlashMode(FlashMode.torch)
          .catchError((_) {});
    }

    await _cameraController.startImageStream(_onFrame);
  }

  void _onFrame(CameraImage image) {
    if (_isPaused || _isProcessing || _isDisposed) return;

    // Skip frames based on config.framesToSkip (0 = no skipping).
    _frameCount++;
    if (config.framesToSkip > 0 && _frameCount % (config.framesToSkip + 1) != 0) {
      return;
    }

    if (!_throttle.canProcess) return;

    _isProcessing = true;
    _processFrame(image).whenComplete(() => _isProcessing = false);
  }

  Future<void> _processFrame(CameraImage image) async {
    try {
      final inputImage = ImageUtils.cameraImageToInputImage(
        image,
        _cameraController,
        _cameraController.description,
      );
      if (inputImage == null) return;

      final barcodes = await _barcodeScanner.processImage(inputImage);
      if (barcodes.isEmpty || _isDisposed) return;

      // ML Kit returns bounding boxes in the rotated (portrait) coordinate
      // space. camW = previewSize.height maps to screen-X; camH to screen-Y.
      final previewSize = _cameraController.value.previewSize;
      final scanRect = previewSize == null ? null : _buildScanRect(previewSize);

      final results = barcodes
          .where((b) => BarcodeUtils.isValid(b.rawValue ?? ''))
          .where((b) => _isInsideScanArea(b.boundingBox, scanRect))
          .map(SmartScanResult.fromBarcode)
          .toList();

      if (results.isNotEmpty) {
        _resultController.add(results);
      }
    } catch (_) {
      // Transient frame errors (e.g. camera closing mid-frame) are ignored.
    }
  }

  /// Computes the scan-window rectangle in ML Kit barcode coordinates.
  /// The scan window is centred at 50 % width / 42 % height of the screen,
  /// matching the widget's [scanRect] calculation.
  Rect _buildScanRect(Size previewSize) {
    final camW = previewSize.height; // rotated: maps to screen X axis
    final camH = previewSize.width;  // rotated: maps to screen Y axis
    final wf = config.scanAreaWidthFactor;
    final hf = config.scanAreaHeightFactor;
    return Rect.fromLTRB(
      (0.5 - wf / 2) * camW,
      (0.42 - hf / 2) * camH,
      (0.5 + wf / 2) * camW,
      (0.42 + hf / 2) * camH,
    );
  }

  /// Returns true if the barcode's centre falls inside the scan window.
  /// Barcodes with no bounding box are always accepted.
  bool _isInsideScanArea(Rect? bbox, Rect? scanRect) {
    if (bbox == null || scanRect == null) return true;
    return scanRect.contains(bbox.center);
  }

  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;

  double get minZoom => _minZoom;
  double get maxZoom => _maxZoom;
  double get currentZoom => _currentZoom;

  Future<void> _loadZoomLimits() async {
    try {
      _minZoom = await _cameraController.getMinZoomLevel();
      _maxZoom = await _cameraController.getMaxZoomLevel();
      _currentZoom = _minZoom;
    } catch (_) {}
  }

  Future<void> setZoom(double zoom) async {
    if (!_cameraController.value.isInitialized) return;
    final clamped = zoom.clamp(_minZoom, _maxZoom);
    try {
      await _cameraController.setZoomLevel(clamped);
      _currentZoom = clamped;
    } catch (_) {}
  }

  /// Toggles the torch / flashlight.
  Future<void> toggleFlash() async {
    if (!_cameraController.value.isInitialized) return;
    final isOn = _cameraController.value.flashMode == FlashMode.torch;
    await _cameraController.setFlashMode(
      isOn ? FlashMode.off : FlashMode.torch,
    );
  }

  /// Returns whether the torch is currently on.
  bool get isFlashOn =>
      _cameraController.value.flashMode == FlashMode.torch;

  /// Pauses frame processing without stopping the camera preview.
  void pause() => _isPaused = true;

  /// Resumes frame processing.
  void resume() {
    _isPaused = false;
    _throttle.reset();
  }

  /// Toggles between front and back camera.
  /// Does NOT close the result stream — scanning continues after reinit.
  Future<void> switchCamera(List<CameraDescription> cameras) async {
    _currentFacing = _currentFacing == CameraFacing.back
        ? CameraFacing.front
        : CameraFacing.back;

    // Stop only the hardware; keep the result stream open.
    _isPaused = true;
    _isProcessing = false;
    if (_cameraController.value.isStreamingImages) {
      await _cameraController.stopImageStream().catchError((_) {});
    }
    await _cameraController.dispose().catchError((_) {});
    await _barcodeScanner.close();

    _isDisposed = false;
    _isPaused = false;
    _frameCount = 0;
    await _initWithFacing(cameras, _currentFacing);
  }

  /// Releases all resources. Safe to call multiple times.
  Future<void> dispose() async {
    _isDisposed = true;
    _isPaused = true;
    if (_cameraController.value.isStreamingImages) {
      await _cameraController.stopImageStream().catchError((_) {});
    }
    await _cameraController.dispose().catchError((_) {});
    await _barcodeScanner.close();
    await _resultController.close();
  }
}

/// Thrown when the camera or scanner cannot be initialised.
class ScannerException implements Exception {
  final String message;
  const ScannerException(this.message);
  @override
  String toString() => 'ScannerException: $message';
}
