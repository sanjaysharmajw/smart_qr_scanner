import 'package:flutter/material.dart';
import '../../models/scan_result.dart';
import '../../models/scanner_theme.dart';

/// Draws premium L-shaped corner brackets + subtle fill around detected codes.
class BoundingBoxPainter extends CustomPainter {
  final List<SmartScanResult> results;
  final ScannerTheme theme;
  final double opacity; // 0.0–1.0, driven by fade-out animation

  const BoundingBoxPainter({
    required this.results,
    required this.theme,
    this.opacity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (results.isEmpty || opacity == 0.0) return;

    final color = theme.borderColor;
    final alpha = opacity.clamp(0.0, 1.0);

    // Subtle fill
    final fillPaint = Paint()
      ..color = color.withAlpha((alpha * 28).round())
      ..style = PaintingStyle.fill;

    // Glow (blurred wide stroke)
    final glowPaint = Paint()
      ..color = color.withAlpha((alpha * 60).round())
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    // Sharp corner stroke
    final cornerPaint = Paint()
      ..color = color.withAlpha((alpha * 230).round())
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final result in results) {
      final box = result.boundingBox;
      if (box == null) continue;

      final rr = RRect.fromRectAndRadius(box, const Radius.circular(8));

      // Fill
      canvas.drawRRect(rr, fillPaint);

      // L-shaped corners
      final len = (box.shortestSide * 0.22).clamp(12.0, 28.0);
      const cr = 8.0;
      _drawLCorners(canvas, box, len, cr, glowPaint);
      _drawLCorners(canvas, box, len, cr, cornerPaint);

      // Corner dots
      final dotPaint = Paint()
        ..color = color.withAlpha((alpha * 255).round())
        ..style = PaintingStyle.fill;

      for (final corner in [
        box.topLeft,
        box.topRight,
        box.bottomLeft,
        box.bottomRight,
      ]) {
        canvas.drawCircle(corner, 3, dotPaint);
      }
    }
  }

  void _drawLCorners(
      Canvas canvas, Rect box, double len, double cr, Paint paint) {
    final l = box.left;
    final t = box.top;
    final r = box.right;
    final b = box.bottom;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(l, t + cr + len)
        ..lineTo(l, t + cr)
        ..arcToPoint(Offset(l + cr, t), radius: Radius.circular(cr), clockwise: false)
        ..lineTo(l + cr + len, t),
      paint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(r - cr - len, t)
        ..lineTo(r - cr, t)
        ..arcToPoint(Offset(r, t + cr), radius: Radius.circular(cr))
        ..lineTo(r, t + cr + len),
      paint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(l, b - cr - len)
        ..lineTo(l, b - cr)
        ..arcToPoint(Offset(l + cr, b), radius: Radius.circular(cr))
        ..lineTo(l + cr + len, b),
      paint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(r - cr - len, b)
        ..lineTo(r - cr, b)
        ..arcToPoint(Offset(r, b - cr), radius: Radius.circular(cr), clockwise: false)
        ..lineTo(r, b - cr - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(BoundingBoxPainter oldDelegate) =>
      oldDelegate.results != results || oldDelegate.opacity != opacity;
}
