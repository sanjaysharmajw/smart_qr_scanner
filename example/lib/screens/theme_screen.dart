import 'package:flutter/material.dart';
import 'package:smart_qr_scanner/smart_qr_scanner.dart';
import 'scanner_screen.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _shimmerCtrl;

  static const _themes = [
    _ThemeData('Neon Cyan', ScannerTheme.neon, Color(0xFF00E5FF),
        [Color(0xFF00B4D8), Color(0xFF00E5FF)]),
    _ThemeData('Indigo', ScannerTheme.light, Color(0xFF536DFE),
        [Color(0xFF3D5AFE), Color(0xFF7C83FF)]),
    _ThemeData('Minimal', ScannerTheme.minimal, Color(0xFFECEFF1),
        [Color(0xFFB0BEC5), Color(0xFFECEFF1)]),
    _ThemeData(
      'Amber',
      ScannerTheme(
        borderColor: Color(0xFFFFB300),
        scanLineColor: Color(0xFFFFB300),
        successColor: Color(0xFFFFB300),
      ),
      Color(0xFFFFB300),
      [Color(0xFFFF8F00), Color(0xFFFFB300)],
    ),
    _ThemeData(
      'Rose',
      ScannerTheme(
        borderColor: Color(0xFFFF4081),
        scanLineColor: Color(0xFFFF4081),
        successColor: Color(0xFFFF4081),
      ),
      Color(0xFFFF4081),
      [Color(0xFFE91E8C), Color(0xFFFF80AB)],
    ),
    _ThemeData(
      'Emerald',
      ScannerTheme(
        borderColor: Color(0xFF00E676),
        scanLineColor: Color(0xFF00E676),
        successColor: Color(0xFF00E676),
      ),
      Color(0xFF00E676),
      [Color(0xFF00C853), Color(0xFF69F0AE)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _themes[_selectedIndex];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildPreviewCard(current),
                  const SizedBox(height: 28),
                  _buildSectionLabel('Choose Theme'),
                  const SizedBox(height: 14),
                  _buildThemeGrid(),
                  const SizedBox(height: 28),
                  _buildSectionLabel('Theme Colors'),
                  const SizedBox(height: 14),
                  _buildColorSection(current),
                  const SizedBox(height: 28),
                ],
              ),
            ),
            _buildApplyBar(context, current),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withAlpha(20), width: 1),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme Studio',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4)),
                Text('Personalise your scanner',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(_ThemeData td) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: td.accent.withAlpha(80), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: td.accent.withAlpha(40),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Simulated camera bg
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A0A10), Color(0xFF1A1A24)],
              ),
            ),
          ),
          // Subtle grid dots
          Positioned.fill(
            child: CustomPaint(painter: _GridDotsPainter()),
          ),
          // Scanner frame preview
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _shimmerCtrl,
              builder: (_, __) => CustomPaint(
                painter: _PreviewPainter(
                    theme: td.theme, lineProgress: _shimmerCtrl.value),
              ),
            ),
          ),
          // Theme name badge
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: td.gradient),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: td.accent.withAlpha(80),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Text(td.name,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
            ),
          ),
          // Live indicator
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(120),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withAlpha(20)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: td.accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: td.accent.withAlpha(150), blurRadius: 6)
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('Preview',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3));
  }

  Widget _buildThemeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: _themes.length,
      itemBuilder: (_, i) {
        final t = _themes[i];
        final selected = i == _selectedIndex;
        return GestureDetector(
          onTap: () => setState(() => _selectedIndex = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: selected
                  ? t.accent.withAlpha(20)
                  : const Color(0xFF16161F),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? t.accent.withAlpha(180) : Colors.white.withAlpha(12),
                width: selected ? 1.5 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                          color: t.accent.withAlpha(60),
                          blurRadius: 16,
                          spreadRadius: 0)
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(colors: t.gradient)
                        : null,
                    color: selected ? null : t.accent.withAlpha(30),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: selected ? Colors.transparent : t.accent.withAlpha(80),
                        width: 1.5),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                                color: t.accent.withAlpha(100),
                                blurRadius: 12)
                          ]
                        : [],
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.black, size: 22)
                      : null,
                ),
                const SizedBox(height: 10),
                Text(
                  t.name,
                  style: TextStyle(
                    color: selected ? t.accent : Colors.white54,
                    fontSize: 11,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorSection(_ThemeData td) {
    final colorRows = [
      ('Border / Corners', td.theme.borderColor),
      ('Scan Line', td.theme.scanLineColor),
      ('Success Ring', td.theme.successColor),
      ('Overlay', td.theme.overlayColor),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16161F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(10), width: 1),
      ),
      child: Column(
        children: [
          for (int i = 0; i < colorRows.length; i++) ...[
            _ColorRow(label: colorRows[i].$1, color: colorRows[i].$2),
            if (i < colorRows.length - 1)
              Divider(color: Colors.white.withAlpha(10), height: 1, indent: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildApplyBar(BuildContext context, _ThemeData td) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E16),
        border: Border(top: BorderSide(color: Colors.white.withAlpha(12))),
      ),
      child: GestureDetector(
        onTap: () => Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, anim, __) => const ScannerScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 350),
          ),
        ),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: td.gradient),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: td.accent.withAlpha(80),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_scanner_rounded,
                  color: Colors.black, size: 22),
              const SizedBox(width: 10),
              Text('Scan with ${td.name}',
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: -0.2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeData {
  final String name;
  final ScannerTheme theme;
  final Color accent;
  final List<Color> gradient;
  const _ThemeData(this.name, this.theme, this.accent, this.gradient);
}

class _ColorRow extends StatelessWidget {
  final String label;
  final Color color;
  const _ColorRow({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final hex =
        // ignore: deprecated_member_use
        '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withAlpha(30), width: 1),
              boxShadow: [
                BoxShadow(
                    color: color.withAlpha(80), blurRadius: 8, spreadRadius: 0)
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(60),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withAlpha(15)),
            ),
            child: Text(hex,
                style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// Draws subtle dot-grid background for the preview card.
class _GridDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withAlpha(12);
    const spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GridDotsPainter _) => false;
}

/// Draws an animated scanner frame preview.
class _PreviewPainter extends CustomPainter {
  final ScannerTheme theme;
  final double lineProgress;
  const _PreviewPainter({required this.theme, required this.lineProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final scanW = size.width * 0.52;
    final scanH = size.height * 0.60;
    final scanRect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: scanW,
      height: scanH,
    );

    // Overlay
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
          scanRect, Radius.circular(theme.borderRadius)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlayPath, Paint()..color = theme.overlayColor);

    // Corner brackets
    final cornerPaint = Paint()
      ..color = theme.borderColor
      ..strokeWidth = theme.borderStrokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final r = theme.borderRadius;
    final len = theme.cornerLength * 0.65;

    void corner(double x, double y, double sx, double sy) {
      canvas.drawPath(
        Path()
          ..moveTo(x + r * sx, y)
          ..lineTo(x + (r + len) * sx, y)
          ..moveTo(x, y + r * sy)
          ..lineTo(x, y + (r + len) * sy),
        cornerPaint,
      );
    }

    corner(scanRect.left, scanRect.top, 1, 1);
    corner(scanRect.right, scanRect.top, -1, 1);
    corner(scanRect.left, scanRect.bottom, 1, -1);
    corner(scanRect.right, scanRect.bottom, -1, -1);

    // Animated scan line
    final lineY = scanRect.top + scanRect.height * lineProgress;
    final lineGradient = LinearGradient(
      colors: [
        Colors.transparent,
        theme.scanLineColor.withAlpha(200),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTRB(scanRect.left, lineY, scanRect.right, lineY));

    canvas.drawLine(
      Offset(scanRect.left + 4, lineY),
      Offset(scanRect.right - 4, lineY),
      Paint()
        ..shader = lineGradient
        ..strokeWidth = theme.scanLineHeight,
    );
  }

  @override
  bool shouldRepaint(_PreviewPainter old) =>
      old.lineProgress != lineProgress || old.theme != theme;
}
