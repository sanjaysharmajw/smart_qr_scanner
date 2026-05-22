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

    // Entrance
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = Tween(begin: 0.65, end: 1.0)
        .chain(CurveTween(curve: Curves.easeOutBack))
        .animate(_entranceCtrl);
    _opacity = Tween(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_entranceCtrl);
    // Starts tilted forward (as if rising from below) → snaps to gentle rest tilt
    _entranceTiltX = Tween(begin: 0.45, end: 0.0)
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
        animation: Listenable.merge(
            [_entranceCtrl, _floatCtrl, _tiltCtrl, _sweepCtrl]),
        builder: (context, _) {
          return Opacity(
            opacity: _opacity.value,
            child: Center(
              child: Transform.translate(
                offset: Offset(0, _floatY.value),
                child: Transform(
                  alignment: Alignment.center,
                  transform: _tiltMatrix(),
                  child: Transform.scale(
                    scale: _scale.value,
                    child: _buildCard(),
                  ),
                ),
              ),
            ),
          );
        },
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
            // QR code with logo centre
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

            // Cyan sweep scan line
            Positioned(
              left: 0,
              right: 0,
              top: _sweep.value * qrSize - 1,
              height: 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFF00E5FF).withAlpha(180),
                      const Color(0xFF00E5FF),
                      const Color(0xFF00E5FF).withAlpha(180),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
