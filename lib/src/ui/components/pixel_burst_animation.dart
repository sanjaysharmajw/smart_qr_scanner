import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Pixel-burst with a genuine "rushing toward the viewer" feel.
///
/// Position and depth are driven by *independent* curves:
///   • XY travel  → easeOutSine  (fast spread that maintains momentum)
///   • Scale/depth → easeInQuart (slow → explosive growth, like a depth rush)
///
/// The combination means blocks first spread outward (natural explosion), then
/// their size explodes dramatically in the last third of the animation — exactly
/// how objects look when they rush from a distance straight at your eyes.
class PixelBurstAnimation extends StatefulWidget {
  final Offset? origin;
  final double spawnZoneWidth;
  final double spawnZoneHeight;
  final VoidCallback? onComplete;
  final Color color;
  final Duration duration;
  final Widget? centerLogo;
  final double logoSize;

  const PixelBurstAnimation({
    super.key,
    this.origin,
    this.spawnZoneWidth  = 220,
    this.spawnZoneHeight = 180,
    this.onComplete,
    this.color    = Colors.white,
    this.duration = const Duration(milliseconds: 1400),
    this.centerLogo,
    this.logoSize = 100,
  });

  @override
  State<PixelBurstAnimation> createState() => _PixelBurstAnimationState();
}

class _PixelBurstAnimationState extends State<PixelBurstAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Block> _blocks;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  bool _completeFired = false;

  void _fireComplete() {
    if (_completeFired) return;
    _completeFired = true;
    widget.onComplete?.call();
  }

  @override
  void initState() {
    super.initState();

    _blocks = _Block.generate(
      520,
      Random(),
      zoneW: widget.spawnZoneWidth,
      zoneH: widget.spawnZoneHeight,
    );

    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _fireComplete();
      })
      ..addListener(() {
        // Fire as soon as blur phase begins (t ≥ 0.70) so navigation
        // starts the moment the bokeh kicks in — not after full animation.
        if (_ctrl.value >= 0.70) _fireComplete();
      });

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.6, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 10,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 90),
    ]).animate(_ctrl);

    _logoOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 45,
      ),
    ]).animate(_ctrl);

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return LayoutBuilder(builder: (context, constraints) {
          final center = widget.origin ??
              Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
          final half = widget.logoSize / 2;

          return Stack(clipBehavior: Clip.none, children: [
            CustomPaint(
              painter: _BurstPainter(
                blocks:   _blocks,
                progress: _ctrl.value,
                origin:   center,
                color:    widget.color,
              ),
              size: Size(constraints.maxWidth, constraints.maxHeight),
            ),
            if (widget.centerLogo != null)
              Positioned(
                left:   center.dx - half,
                top:    center.dy - half,
                width:  widget.logoSize,
                height: widget.logoSize,
                child: Opacity(
                  opacity: _logoOpacity.value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: Center(child: widget.centerLogo),
                  ),
                ),
              ),
          ]);
        });
      },
    );
  }
}

// ── Block ─────────────────────────────────────────────────────────────────────

class _Block {
  final Offset spawn;       // offset within QR zone (relative to origin)
  final double angle;       // outward direction (radians)
  final double distance;    // total XY travel (px)
  final double w;           // base world width
  final double h;           // base world height
  final double scaleStart;  // scale at t = 0  (0.5 – 0.9, clearly visible)
  final double scaleEnd;    // scale at t = 1  (2.5 – 6.0, huge)
  final double fadeStart;   // normalised t where opacity starts dropping
  final double delay;       // per-block micro-stagger

  const _Block({
    required this.spawn,
    required this.angle,
    required this.distance,
    required this.w,
    required this.h,
    required this.scaleStart,
    required this.scaleEnd,
    required this.fadeStart,
    required this.delay,
  });

  static List<_Block> generate(
    int count,
    Random rng, {
    required double zoneW,
    required double zoneH,
  }) {
    return List.generate(count, (_) {
      // Spawn inside QR zone; 30 % of blocks get extra spread beyond the zone
      // so deep-layer blocks populate a wider area for richer depth density.
      final extraSpread = rng.nextDouble() < 0.30 ? 1.6 : 1.0;
      final spawnX = (rng.nextDouble() - 0.5) * zoneW * extraSpread;
      final spawnY = (rng.nextDouble() - 0.5) * zoneH * extraSpread;

      // Outward angle + gentle spread.
      final base   = atan2(spawnY, spawnX);
      final spread = (rng.nextDouble() - 0.5) * (pi / 2.2);
      final angle  = base + spread;

      final roll = rng.nextDouble();
      final double w, h, scaleStart, scaleEnd, distance;

      if (roll < 0.48) {
        // ── Micro pixels ──
        final s  = 12.0 + rng.nextDouble() * 18;
        final ar = rng.nextDouble() < 0.30
            ? 0.25 + rng.nextDouble() * 0.35
            : 0.80 + rng.nextDouble() * 0.40;
        w = s; h = s * ar;
        scaleStart = 0.60 + rng.nextDouble() * 0.30;
        scaleEnd   = 2.50 + rng.nextDouble() * 3.50;
        distance   = 90   + rng.nextDouble() * 190;
      } else if (roll < 0.80) {
        // ── Medium blocks ──
        final s  = 30.0 + rng.nextDouble() * 40;
        final ar = rng.nextDouble() < 0.25
            ? 0.25 + rng.nextDouble() * 0.40
            : 0.75 + rng.nextDouble() * 0.50;
        w = s; h = s * ar;
        scaleStart = 0.45 + rng.nextDouble() * 0.30;
        scaleEnd   = 2.00 + rng.nextDouble() * 2.80;
        distance   = 190  + rng.nextDouble() * 230;
      } else {
        // ── Large slabs ──
        final s  = 80.0 + rng.nextDouble() * 80;
        final ar = rng.nextDouble() < 0.35
            ? 0.20 + rng.nextDouble() * 0.35
            : 0.65 + rng.nextDouble() * 0.60;
        w = s; h = s * ar;
        scaleStart = 0.25 + rng.nextDouble() * 0.25;
        scaleEnd   = 1.20 + rng.nextDouble() * 1.60;
        distance   = 340  + rng.nextDouble() * 300;
      }

      return _Block(
        spawn:      Offset(spawnX, spawnY),
        angle:      angle,
        distance:   distance,
        w:          w,
        h:          h,
        scaleStart: scaleStart,
        scaleEnd:   scaleEnd,
        fadeStart:  0.68 + rng.nextDouble() * 0.22,
        delay:      rng.nextDouble() * 0.10,
      );
    });
  }
}

// ── Depth-of-field helper ─────────────────────────────────────────────────────

/// One pre-computed draw call (rect + alpha).
class _Cmd {
  final Rect rect;
  final int  alpha;
  const _Cmd(this.rect, this.alpha);
}

/// Renders [cmds] into an offscreen layer blurred by [sigma], then composites
/// onto [canvas].  Uses TileMode.decal so blur doesn't bleed outside the rect.
void _drawBlurred(
  Canvas canvas, Size size, List<_Cmd> cmds, Color color, double sigma,
) {
  if (cmds.isEmpty) return;
  canvas.saveLayer(
    Rect.fromLTWH(0, 0, size.width, size.height),
    Paint()
      ..imageFilter = ui.ImageFilter.blur(
          sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.decal),
  );
  for (final c in cmds) {
    canvas.drawRect(c.rect, Paint()..color = color.withAlpha(c.alpha));
  }
  canvas.restore();
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _BurstPainter extends CustomPainter {
  final List<_Block> blocks;
  final double progress;
  final Offset origin;
  final Color color;

  const _BurstPainter({
    required this.blocks,
    required this.progress,
    required this.origin,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Shockwave flash (first 35 %) ────────────────────────────────────────
    if (progress < 0.35) {
      final fp     = progress / 0.35;
      final opacity = pow(1.0 - fp, 1.6) * 0.88;
      final radius  = 6.0 + fp * 230.0;
      canvas.drawCircle(
        origin, radius,
        Paint()
          ..color      = color.withAlpha((opacity * 255).round())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36),
      );
      canvas.drawCircle(
        origin, radius * 0.22,
        Paint()..color = color.withAlpha(((1.0 - fp * fp) * 230).round()),
      );
    }

    // ── Sort blocks into 4 depth buckets ────────────────────────────────────
    //   far     (t < 0.24)       σ 3.5  — distant haze, atmospheric dimming
    //   sharp   (0.24 – 0.65)    σ 0    — crisp focal plane
    //   hclose  (0.65 – 0.80)    σ 7    — transitioning past the lens
    //   close   (t > 0.80)       σ 16   — extreme bokeh, full depth rush
    final far    = <_Cmd>[];
    final sharp  = <_Cmd>[];
    final hclose = <_Cmd>[];
    final close  = <_Cmd>[];

    for (final b in blocks) {
      final t = ((progress - b.delay) / (1.0 - b.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final posEase = Curves.easeOutSine.transform(t);
      final scaleT  = t * t * t * t; // easeInQuart
      final scale   = b.scaleStart + (b.scaleEnd - b.scaleStart) * scaleT;

      final pos = origin +
          b.spawn +
          Offset(cos(b.angle) * b.distance * posEase,
                 sin(b.angle) * b.distance * posEase);

      final opacity = t < b.fadeStart
          ? 1.0
          : 1.0 - ((t - b.fadeStart) / (1.0 - b.fadeStart));
      if (opacity <= 0) continue;

      // Atmospheric dimming: far blocks are slightly fainter (distance haze).
      final depthDim = t < 0.24 ? 0.45 + (t / 0.24) * 0.55 : 1.0;
      final alpha    = (opacity.clamp(0.0, 1.0) * depthDim * 255).round();

      final cmd = _Cmd(
        Rect.fromCenter(center: pos, width: b.w * scale, height: b.h * scale),
        alpha,
      );

      if (t < 0.24) {
        far.add(cmd);
      } else if (t < 0.65) {
        sharp.add(cmd);
      } else if (t < 0.80) {
        hclose.add(cmd);
      } else {
        close.add(cmd);
      }
    }

    // ── Render depth layers back → front ────────────────────────────────────
    _drawBlurred(canvas, size, far,    color, 3.5);   // distance haze

    for (final c in sharp) {                           // razor-sharp focal plane
      canvas.drawRect(c.rect, Paint()..color = color.withAlpha(c.alpha));
    }

    _drawBlurred(canvas, size, hclose, color, 7.0);   // soft transition blur
    _drawBlurred(canvas, size, close,  color, 16.0);  // extreme bokeh rush
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.progress != progress;
}
