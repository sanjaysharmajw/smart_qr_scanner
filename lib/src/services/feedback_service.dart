import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:vibration/vibration.dart';

/// Haptic pattern definition: list of [vibrate ms, pause ms, ...] pairs.
class HapticPattern {
  final List<int> pattern; // alternating on/off durations in ms
  const HapticPattern(this.pattern);

  static const short       = HapticPattern([60]);
  static const medium      = HapticPattern([100]);
  static const long        = HapticPattern([200]);
  static const doubleShort = HapticPattern([60, 80, 60]);
  static const tripleShort = HapticPattern([50, 60, 50, 60, 50]);

  /// Returns the pattern suited for the given [BarcodeType].
  static HapticPattern forType(BarcodeType type) {
    switch (type) {
      case BarcodeType.url:
        return doubleShort;
      case BarcodeType.email:
        return medium;
      case BarcodeType.phone:
        return tripleShort;
      case BarcodeType.wifi:
        return long;
      case BarcodeType.contactInfo:
        return doubleShort;
      default:
        return short;
    }
  }
}

/// Provides haptic feedback on scan events.
class FeedbackService {
  FeedbackService._();

  static bool _vibrationAvailable = false;
  static bool _initialized = false;

  /// Call once before using feedback. Safe to call multiple times.
  static Future<void> init() async {
    if (_initialized) return;
    _vibrationAvailable = await Vibration.hasVibrator() == true;
    _initialized = true;
  }

  /// Triggers a short vibration pulse. No-op if device has no vibrator.
  static Future<void> vibrate({int duration = 80}) async {
    if (!_initialized) await init();
    if (!_vibrationAvailable) return;
    await Vibration.vibrate(duration: duration);
  }

  /// Triggers a typed haptic pattern. Falls back to a single pulse if the
  /// device does not support custom patterns.
  static Future<void> vibratePattern(HapticPattern pattern) async {
    if (!_initialized) await init();
    if (!_vibrationAvailable) return;
    final hasPat = await Vibration.hasCustomVibrationsSupport() == true;
    if (hasPat && pattern.pattern.length > 1) {
      await Vibration.vibrate(pattern: pattern.pattern);
    } else {
      await Vibration.vibrate(duration: pattern.pattern.first);
    }
  }

  /// Triggers haptic feedback on a successful scan.
  /// Uses a type-aware pattern when [barcodeType] is provided.
  static Future<void> scanSuccess({
    bool vibrate = true,
    BarcodeType? barcodeType,
  }) async {
    if (!vibrate) return;
    if (barcodeType != null) {
      await vibratePattern(HapticPattern.forType(barcodeType));
    } else {
      await FeedbackService.vibrate();
    }
  }

  /// Resets state. Call when the scanner is fully disposed.
  static void dispose() {
    _initialized = false;
  }
}
