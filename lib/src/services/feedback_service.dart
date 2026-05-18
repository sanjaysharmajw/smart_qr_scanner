import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

/// Provides haptic and audio feedback on scan events.
class FeedbackService {
  FeedbackService._();

  static final AudioPlayer _player = AudioPlayer();
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

  /// Plays a beep sound from the package's bundled asset.
  /// Falls back silently if the asset is missing.
  static Future<void> playBeep() async {
    try {
      await _player.play(
        AssetSource('sounds/beep.mp3'),
        volume: 0.6,
      );
    } catch (_) {
      // Sound asset optional — fail silently.
    }
  }

  /// Runs both [vibrate] and [playBeep] in parallel.
  static Future<void> scanSuccess({
    bool vibrate = true,
    bool sound = true,
  }) async {
    await Future.wait([
      if (vibrate) FeedbackService.vibrate(),
      if (sound) playBeep(),
    ]);
  }

  /// Release audio resources. Call when the scanner is fully disposed.
  static Future<void> dispose() async {
    await _player.dispose();
    _initialized = false;
  }
}
