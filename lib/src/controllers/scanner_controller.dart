import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:image_picker/image_picker.dart';

import '../engine/scanner_engine.dart';
import '../models/scan_result.dart';
import '../models/scanner_config.dart';
import '../services/feedback_service.dart';
import '../services/history_service.dart';
import '../services/permission_service.dart';
import '../utils/barcode_utils.dart';

/// The primary API for consumers of smart_qr_scanner.
///
/// Usage:
/// ```dart
/// final controller = SmartQrScannerController(config: ScannerConfig());
/// await controller.initialize();
/// controller.onScan = (result) => print(result.rawValue);
/// // later:
/// await controller.dispose();
/// ```
class SmartQrScannerController extends ChangeNotifier {
  final ScannerConfig config;

  late ScannerEngine _engine;
  late HistoryService _history;
  StreamSubscription<List<SmartScanResult>>? _subscription;
  Timer? _timeoutTimer;
  Timer? _duplicateTimer;

  final _scanBroadcast = StreamController<SmartScanResult>.broadcast();
  final _rawBroadcast = StreamController<List<SmartScanResult>>.broadcast();

  /// Stream of every new (non-duplicate) scan result.
  /// Subscribe here instead of (or in addition to) [onScan].
  Stream<SmartScanResult> get scanEvents => _scanBroadcast.stream;

  /// Stream of every raw ML Kit batch (includes duplicates).
  /// Subscribe here instead of (or in addition to) [onRawScan].
  Stream<List<SmartScanResult>> get rawScanEvents => _rawBroadcast.stream;

  String? _lastScannedValue;
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _isDisposed = false;
  bool _isPaused = false;
  bool _isFlashOn = false;
  bool _isSwitching = false;
  CameraPermissionStatus _permissionStatus = CameraPermissionStatus.denied;
  String? _errorMessage;

  // ── Public callbacks ──────────────────────────────────────────────────────

  /// Called for every new (non-duplicate) successful scan.
  void Function(SmartScanResult result)? onScan;

  /// Called with every batch of raw results from ML Kit (including duplicates).
  void Function(List<SmartScanResult> results)? onRawScan;

  /// Called when a scan timeout fires.
  void Function()? onTimeout;

  /// Called when an error occurs.
  void Function(String message)? onError;

  // ── Public state (read-only) ──────────────────────────────────────────────

  bool get isInitialized => _isInitialized;
  bool get isPaused => _isPaused;
  bool get isFlashOn => _isFlashOn;
  bool get isDisposed => _isDisposed;
  bool get isSwitching => _isSwitching;
  CameraPermissionStatus get permissionStatus => _permissionStatus;
  String? get errorMessage => _errorMessage;
  List<SmartScanResult> get history => _history.items;
  CameraController? get cameraController =>
      _isInitialized ? _engine.cameraController : null;

  double get minZoom => _isInitialized ? _engine.minZoom : 1.0;
  double get maxZoom => _isInitialized ? _engine.maxZoom : 1.0;
  double get currentZoom => _isInitialized ? _engine.currentZoom : 1.0;

  SmartQrScannerController({required this.config}) {
    _history = HistoryService(maxItems: config.maxHistoryItems);
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Requests camera permission then initialises the scanner engine.
  /// Safe to call concurrently — extra calls while one is in-flight are no-ops.
  Future<void> initialize() async {
    if (_isInitialized || _isInitializing || _isDisposed) return;
    _isInitializing = true;

    await FeedbackService.init();
    await _history.load();

    _permissionStatus = await PermissionService.requestCamera();
    notifyListeners();

    if (_permissionStatus != CameraPermissionStatus.granted) {
      _isInitializing = false;
      _setError('Camera permission not granted');
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      _isInitializing = false;
      final isSimulator = Platform.isIOS &&
          Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');
      _setError(isSimulator ? '__ios_simulator__' : 'No cameras available on this device');
      return;
    }

    _engine = ScannerEngine(config);

    try {
      await _engine.init(cameras);
    } on ScannerException catch (e) {
      _isInitializing = false;
      _setError(e.message);
      return;
    }

    _subscription = _engine.resultStream.listen(_handleResults);
    _startTimeoutTimer();

    _isInitializing = false;
    _isInitialized = true;
    notifyListeners();
  }

  // ── Controls ──────────────────────────────────────────────────────────────

  void pause() {
    if (!_isInitialized || _isPaused) return;
    _engine.pause();
    _isPaused = true;
    notifyListeners();
  }

  void resume() {
    if (!_isInitialized || !_isPaused) return;
    _engine.resume();
    _isPaused = false;
    _startTimeoutTimer();
    notifyListeners();
  }

  Future<void> toggleFlash() async {
    if (!_isInitialized) return;
    await _engine.toggleFlash();
    _isFlashOn = _engine.isFlashOn;
    notifyListeners();
  }

  Future<void> setZoom(double zoom) async {
    if (!_isInitialized) return;
    await _engine.setZoom(zoom);
    notifyListeners();
  }

  Future<void> switchCamera() async {
    if (!_isInitialized || _isSwitching) return;

    // Signal the UI to swap _CameraPreview for a black placeholder BEFORE
    // disposing the old controller, preventing the "buildPreview on disposed
    // CameraController" crash.
    _isSwitching = true;
    notifyListeners();

    // Wait for Flutter to render the black placeholder so _CameraPreview is
    // fully removed from the tree before we dispose the old controller.
    final postFrame = Completer<void>();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => postFrame.complete());
    await postFrame.future;

    final cameras = await availableCameras();
    await _engine.switchCamera(cameras);
    _isFlashOn = false;
    _isSwitching = false;
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  /// Picks an image from the device gallery and scans it for barcodes.
  /// Fires [onScan] on success or [onError] if no barcode is found.
  Future<void> scanFromGallery() async {
    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    } catch (_) {
      onError?.call('Could not open gallery');
      return;
    }
    if (picked == null) return;

    final scanner = BarcodeScanner(formats: config.effectiveFormats);
    try {
      final barcodes = await scanner
          .processImage(InputImage.fromFilePath(picked.path));
      final results = barcodes
          .where((b) => BarcodeUtils.isValid(b.rawValue ?? ''))
          .map(SmartScanResult.fromBarcode)
          .toList();

      if (results.isEmpty) {
        onError?.call('No QR code or barcode found in this image');
        return;
      }

      final result = results.first;
      if (config.enableScanHistory) _history.add(result);
      FeedbackService.scanSuccess(
        vibrate: config.enableVibration,
        barcodeType: result.type,
      );
      if (!_scanBroadcast.isClosed) _scanBroadcast.add(result);
      onScan?.call(result);
      notifyListeners();
    } catch (_) {
      onError?.call('Failed to read image');
    } finally {
      await scanner.close();
    }
  }

  /// Returns a [Future] that resolves with the next successful scan result.
  /// Useful for the single-scan flow without needing a callback.
  Future<SmartScanResult> scanOnce() {
    final completer = Completer<SmartScanResult>();
    void Function(SmartScanResult)? prev = onScan;
    onScan = (result) {
      onScan = prev;
      if (!completer.isCompleted) completer.complete(result);
    };
    return completer.future;
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _handleResults(List<SmartScanResult> results) {
    _cancelTimeoutTimer();

    if (!_rawBroadcast.isClosed) _rawBroadcast.add(results);
    onRawScan?.call(results);

    for (final result in results) {
      if (!result.isSuccess) continue;

      final value = result.rawValue;

      if (config.preventDuplicates && value == _lastScannedValue) continue;

      _lastScannedValue = value;
      _scheduleDuplicateClear();

      final enriched = result.copyWith(confidence: _estimateConfidence(result));

      if (config.enableScanHistory) _history.add(enriched);

      config.onAnalyticsEvent?.call(value, enriched.formatName);

      FeedbackService.scanSuccess(
        vibrate: config.enableVibration,
        barcodeType: enriched.type,
      );

      if (!_scanBroadcast.isClosed) _scanBroadcast.add(enriched);
      onScan?.call(enriched);
      notifyListeners();

      if (config.scanMode == ScanMode.single) {
        pause();
        return;
      }
    }

    if (config.scanTimeout != null) _startTimeoutTimer();
  }

  /// Heuristic confidence: longer raw values with valid structure score higher.
  double _estimateConfidence(SmartScanResult result) {
    if (result.rawValue.isEmpty) return 0.0;
    if (result.rawValue.length > 50) return 0.99;
    if (result.rawValue.length > 10) return 0.95;
    return 0.85;
  }

  void _startTimeoutTimer() {
    _cancelTimeoutTimer();
    final timeout = config.scanTimeout;
    if (timeout == null) return;
    _timeoutTimer = Timer(timeout, () {
      onTimeout?.call();
    });
  }

  void _cancelTimeoutTimer() => _timeoutTimer?.cancel();

  void _scheduleDuplicateClear() {
    _duplicateTimer?.cancel();
    _duplicateTimer = Timer(config.duplicatePreventionWindow, () {
      _lastScannedValue = null;
    });
  }

  void _setError(String message) {
    _errorMessage = message;
    onError?.call(message);
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _cancelTimeoutTimer();
    _duplicateTimer?.cancel();
    await _subscription?.cancel();    // stop handler first
    await _scanBroadcast.close();     // then close broadcasts before engine emits more
    await _rawBroadcast.close();
    if (_isInitialized) await _engine.dispose();
    FeedbackService.dispose();
    super.dispose();
  }
}
