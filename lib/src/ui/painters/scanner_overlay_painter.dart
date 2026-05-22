import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../models/scanner_theme.dart';

/// Draws ONLY the L-shaped corner brackets around the scan window.
/// No dark mask — camera is fully visible. Optional detection glow.
class ScannerOverlayPainter extends CustomPainter {
  final Rect scanRect;
  final ScannerTheme theme;
  final double scanLineProgress;
  final bool detecting;

  const ScannerOverlayPainter({
    required this.scanRect,
    required this.theme,
    required this.scanLineProgress,
    this.detecting = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawOuterMask(canvas, size);
    if (detecting) _drawDetectionGlow(canvas);
    _drawCorners(canvas);
    _drawScanLine(canvas);
  }

  // Draws a dark semi-transparent overlay everywhere OUTSIDE the scan window.
  void _drawOuterMask(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      scanRect, Radius.circular(theme.borderRadius),
    );
    // Punch a transparent hole for the scan area, darken the rest.
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = Colors.black.withAlpha(140));

    // Soft inner shadow along the edges of the cutout for depth.
    canvas.save();
    canvas.clipRRect(rrect);
    final innerShadow = Paint()
      ..shader = ui.Gradient.radial(
        scanRect.center,
        scanRect.longestSide * 0.68,
        [const Color(0x00000000), Colors.black.withAlpha(55)],
        [0.55, 1.0],
      );
    canvas.drawRect(scanRect, innerShadow);
    canvas.restore();
  }

  void _drawCorners(Canvas canvas) {
    final c = detecting ? theme.successColor : theme.borderColor;
    const r = 12.0;
    const len = 32.0;
    const sw = 3.5;

    final glow = Paint()
      ..color = c.withAlpha(detecting ? 120 : 70)
      ..strokeWidth = sw + 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final line = Paint()
      ..color = c
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    void bracket(double x, double y, double sx, double sy) {
      final p = Path()
        ..moveTo(x + r * sx, y)
        ..arcToPoint(Offset(x, y + r * sy),
            radius: const Radius.circular(r), clockwise: sx != sy)
        ..moveTo(x + r * sx, y)
        ..lineTo(x + (r + len) * sx, y)
        ..moveTo(x, y + r * sy)
        ..lineTo(x, y + (r + len) * sy);
      canvas.drawPath(p, glow);
      canvas.drawPath(p, line);
    }

    bracket(scanRect.left, scanRect.top, 1, 1);
    bracket(scanRect.right, scanRect.top, -1, 1);
    bracket(scanRect.left, scanRect.bottom, 1, -1);
    bracket(scanRect.right, scanRect.bottom, -1, -1);
  }

  void _drawDetectionGlow(Canvas canvas) {
    final c = theme.successColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          scanRect.inflate(4), Radius.circular(theme.borderRadius + 4)),
      Paint()
        ..color = c.withAlpha(80)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  void _drawScanLine(Canvas canvas) {
    final scanY = scanRect.top + scanLineProgress * scanRect.height;

    // Soft glow behind the line
    canvas.drawRect(
      Rect.fromLTWH(scanRect.left, scanY - 6, scanRect.width, 12),
      Paint()
        ..color = theme.scanLineColor.withAlpha(30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Gradient scan line
    canvas.drawRect(
      Rect.fromLTWH(scanRect.left, scanY - theme.scanLineHeight / 2,
          scanRect.width, theme.scanLineHeight),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(scanRect.left, scanY),
          Offset(scanRect.right, scanY),
          [
            const Color(0x00FFFFFF),
            theme.scanLineColor.withAlpha(220),
            const Color(0x00FFFFFF),
          ],
          [0.0, 0.5, 1.0],
        ),
    );
  }

  @override
  bool shouldRepaint(ScannerOverlayPainter old) =>
      old.scanLineProgress != scanLineProgress ||
      old.scanRect != scanRect ||
      old.theme != theme ||
      old.detecting != detecting;
}
