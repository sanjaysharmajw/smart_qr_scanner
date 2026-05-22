import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class HolographicQrOverlay extends StatefulWidget {
  final String rawValue;
  final VoidCallback? onDismiss;
  final Duration autoDismissAfter;

  const HolographicQrOverlay({
    super.key,
    required this.rawValue,
    this.onDismiss,
    this.autoDismissAfter = const Duration(milliseconds: 2400),
  });

  @override
  State<HolographicQrOverlay> createState() => _HolographicQrOverlayState();
}

class _HolographicQrOverlayState extends State<HolographicQrOverlay>
    with TickerProviderStateMixin {

  // ── Entrance (scale + fade + initial tilt snap) ───────────────────────────
  late final AnimationController _entranceCtrl;
  late final Animation<double>   _scale;
  late final Animation<double>   _opacity;
  late final Animation<double>   _entranceTiltX; // neeche se aakar seedha hona

  // ── Entrance slide-up ─────────────────────────────────────────────────────
  late final Animation<double>   _slideY;

  // ── Continuous float (Y translation) ──────────────────────────────────────
  late final AnimationController _floatCtrl;
  late final Animation<double>   _floatY;

  // ── Gentle 3D tilt oscillation ────────────────────────────────────────────
  late final AnimationController _tiltCtrl;
  late final Animation<double>   _tiltX; // forward/back
  late final Animation<double>   _tiltY; // left/right

  // ── Scan-line sweep ───────────────────────────────────────────────────────
  late final AnimationController _sweepCtrl;
  late final Animation<double>   _sweep;

  bool _dismissing = false;

  @override
  void initState() {
    super.initState();

    // Entrance — small → big succession with overshoot settle
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Scale: tiny → overshoot → settle  (growth clearly visible)
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.05, end: 1.18)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.18, end: 0.94)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.94, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
    ]).animate(_entranceCtrl);

    // Opacity: fade in quickly so scale growth is fully visible
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 75),
    ]).animate(_entranceCtrl);

    // Tilt: starts tilted forward → settles
    _entranceTiltX = Tween(begin: 0.55, end: 0.0)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_entranceCtrl);

    // Slide up from below
    _slideY = Tween(begin: 40.0, end: 0.0)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_entranceCtrl);

    // Float
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _floatY = Tween(begin: -6.0, end: 6.0)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_floatCtrl);

    // 3D tilt oscillation — visible wobble
    _tiltCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _tiltX = Tween(begin: -0.30, end: 0.30)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_tiltCtrl);
    _tiltY = Tween(begin: -0.22, end: 0.22)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_tiltCtrl);

    // Sweep
    _sweepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _sweep = Tween(begin: 0.0, end: 1.0).animate(_sweepCtrl);

    _entranceCtrl.forward();

    if (widget.onDismiss != null) {
      Future.delayed(widget.autoDismissAfter, () {
        if (mounted && !_dismissing) _dismiss();
      });
    }
  }

  void _dismiss() {
    if (_dismissing || widget.onDismiss == null) return;
    _dismissing = true;
    _entranceCtrl.reverse().then((_) {
      if (mounted) widget.onDismiss!();
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _floatCtrl.dispose();
    _tiltCtrl.dispose();
    _sweepCtrl.dispose();
    super.dispose();
  }

  Matrix4 _tiltMatrix() {
    return Matrix4.identity()
      ..setEntry(3, 2, 0.002) // perspective
      ..rotateX(_entranceTiltX.value + _tiltX.value)
      ..rotateY(_tiltY.value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismiss,
      behavior: HitTestBehavior.translucent,
      child: AnimatedBuilder(
        animation: Listenable.merge([_entranceCtrl, _floatCtrl, _tiltCtrl]),
        builder: (context, child) {
          return Opacity(
            opacity: _opacity.value,
            child: Center(
              child: Transform.translate(
                offset: Offset(0, _floatY.value + _slideY.value),
                child: Transform(
                  alignment: Alignment.center,
                  transform: _tiltMatrix(),
                  child: Transform.scale(
                    scale: _scale.value,
                    child: child,
                  ),
                ),
              ),
            ),
          );
        },
        // card passed as static child — not rebuilt by outer animation ticks
        child: RepaintBoundary(child: _buildCard()),
      ),
    );
  }

  Widget _buildCard() {
    const qrSize = 160.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: qrSize,
        height: qrSize,
        child: Stack(
          children: [
            // QR code — static, never rebuilds
            PrettyQrView.data(
              data: widget.rawValue,
              decoration: const PrettyQrDecoration(
                shape: PrettyQrSmoothSymbol(color: Colors.white),
                image: PrettyQrDecorationImage(
                  image: AssetImage('assets/logo.png'),
                  scale: 0.28,
                ),
              ),
            ),

            // Sweep — isolated builder, only this Positioned repaints
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _sweepCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _SweepPainter(progress: _sweep.value, size: qrSize),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sweep painter — repaints only the scan line ───────────────────────────────

class _SweepPainter extends CustomPainter {
  final double progress;
  final double size;
  const _SweepPainter({required this.progress, required this.size});

  @override
  void paint(Canvas canvas, Size s) {
    final y = progress * size - 1;
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Colors.transparent,
          Color(0xB400E5FF),
          Color(0xFF00E5FF),
          Color(0xB400E5FF),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, y, s.width, 2));
    canvas.drawRect(Rect.fromLTWH(0, y, s.width, 2), paint);
  }

  @override
  bool shouldRepaint(_SweepPainter old) => old.progress != progress;
}
