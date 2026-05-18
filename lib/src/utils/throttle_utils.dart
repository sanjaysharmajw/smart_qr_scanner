import 'dart:async';

/// Limits how often [action] is called; subsequent calls within [duration] are
/// dropped — not queued — so the scanner never processes a backlog of frames.
class FrameThrottle {
  final Duration duration;
  DateTime _lastCall = DateTime.fromMillisecondsSinceEpoch(0);

  FrameThrottle({this.duration = const Duration(milliseconds: 100)});

  /// Returns true and records timestamp if enough time has passed.
  bool get canProcess {
    final now = DateTime.now();
    if (now.difference(_lastCall) >= duration) {
      _lastCall = now;
      return true;
    }
    return false;
  }

  void reset() => _lastCall = DateTime.fromMillisecondsSinceEpoch(0);
}

/// Debounces rapid calls; only fires [action] after [delay] of silence.
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() => _timer?.cancel();
}

typedef VoidCallback = void Function();
