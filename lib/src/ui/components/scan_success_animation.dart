import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/scanner_theme.dart';

/// Multi-stage success animation: flash → ripple rings → checkmark → fade-out.
class ScanSuccessAnimation extends StatefulWidget {
  final ScannerTheme theme;
  final VoidCallback? onComplete;

  const ScanSuccessAnimation({
    super.key,
    required this.theme,
    this.onComplete,
  });

  @override
  State<ScanSuccessAnimation> createState() => _ScanSuccessAnimationState();
}

class _ScanSuccessAnimationState extends State<ScanSuccessAnimation>
    with TickerProviderStateMixin {
  // Stage 1 – white flash
  late AnimationController _flashCtrl;
  late Animation<double> _flashAnim;

  // Stage 2 – ripple rings
  late AnimationController _rippleCtrl;
  late Animation<double> _rippleAnim;

  // Stage 3 – checkmark scale + hold + fade-out
  late AnimationController _checkCtrl;
  late Animation<double> _checkScale;
  late Animation<double> _checkFade;

  @override
  void initState() {
    super.initState();

    // Flash: quick in-out
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _flashAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.55), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.55, end: 0.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _flashCtrl, curve: Curves.easeOut));

    // Ripple: two expanding rings
    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _rippleAnim =
        CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut);

    // Check: elastic in, hold, then fade-out
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _checkScale = CurvedAnimation(
      parent: _checkCtrl,
      curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
    );
    _checkFade = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 65),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 35),
    ]).animate(_checkCtrl);

    _runSequence();
  }

  Future<void> _runSequence() async {
    await _flashCtrl.forward();
    if (!mounted) return;
    _rippleCtrl.forward();
    await _checkCtrl.forward();
    if (!mounted) return;
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _flashCtrl.dispose();
    _rippleCtrl.dispose();
    _checkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.theme.successColor;

    return Stack(
      children: [
        // ── White screen flash ──────────────────────────────────────────
        AnimatedBuilder(
          animation: _flashAnim,
          builder: (_, __) => _flashAnim.value > 0
              ? Positioned.fill(
                  child: ColoredBox(
                    color: Colors.white.withAlpha(
                        (_flashAnim.value * 255).round()),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // ── Ripple rings + checkmark ────────────────────────────────────
        Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_rippleAnim, _checkCtrl]),
            builder: (_, __) => FadeTransition(
              opacity: _checkFade,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ripple
                  if (_rippleAnim.value > 0)
                    _RippleRing(
                      color: color,
                      progress: _rippleAnim.value,
                      maxRadius: 110,
                      delay: 0.0,
                    ),
                  // Inner ripple
                  if (_rippleAnim.value > 0)
                    _RippleRing(
                      color: color,
                      progress: _rippleAnim.value,
                      maxRadius: 80,
                      delay: 0.15,
                    ),
                  // Checkmark circle
                  Transform.scale(
                    scale: _checkScale.value,
                    child: _CheckCircle(color: color),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Expanding ring ────────────────────────────────────────────────────────────

class _RippleRing extends StatelessWidget {
  final Color color;
  final double progress; // 0–1
  final double maxRadius;
  final double delay; // 0–1, start offset

  const _RippleRing({
    required this.color,
    required this.progress,
    required this.maxRadius,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final t = ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);
    if (t <= 0) return const SizedBox.shrink();

    final radius = maxRadius * t;
    final alpha = ((1.0 - t) * 180).round();

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withAlpha(alpha),
          width: math.max(1.0, 3.0 * (1.0 - t)),
        ),
      ),
    );
  }
}

// ── Check circle ──────────────────────────────────────────────────────────────

class _CheckCircle extends StatelessWidget {
  final Color color;
  const _CheckCircle({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withAlpha(255), color.withAlpha(200)],
          stops: const [0.0, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(140),
            blurRadius: 28,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: color.withAlpha(60),
            blurRadius: 60,
            spreadRadius: 8,
          ),
        ],
      ),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
    );
  }
}
