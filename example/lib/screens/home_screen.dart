import 'package:flutter/material.dart';
import 'package:smart_qr_scanner/smart_qr_scanner.dart';
import 'scanner_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _accent = Color(0xFF0066FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // ── Header ───────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _accent.withAlpha(60),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart QR Scanner',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111111),
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        'Powered by ML Kit',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888888),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Main scan button ─────────────────────────────────────────
              _MainScanBtn(
                onTap: () => _open(context, const ScannerConfig(
                  scanMode: ScanMode.single,
                  enableVibration: true,
                  enableSound: true,
                )),
              ),

              const SizedBox(height: 28),

              // ── Feature section ──────────────────────────────────────────
              const _SectionTitle('Features'),
              const SizedBox(height: 14),

              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
                children: [
                  _FeatureBtn(
                    icon: Icons.all_inclusive_rounded,
                    label: 'Continuous',
                    color: const Color(0xFF7B2FFF),
                    onTap: () => _open(context, const ScannerConfig(
                      scanMode: ScanMode.continuous,
                      enableVibration: true,
                      enableSound: true,
                    )),
                  ),
                  _FeatureBtn(
                    icon: Icons.flash_on_rounded,
                    label: 'With Flash',
                    color: const Color(0xFFFF9500),
                    onTap: () => _open(context, const ScannerConfig(
                      scanMode: ScanMode.single,
                      enableFlash: true,
                      enableVibration: true,
                    )),
                  ),
                  _FeatureBtn(
                    icon: Icons.copy_all_rounded,
                    label: 'No Duplicates',
                    color: const Color(0xFF34C759),
                    onTap: () => _open(context, const ScannerConfig(
                      scanMode: ScanMode.continuous,
                      preventDuplicates: true,
                      duplicatePreventionWindow: Duration(seconds: 5),
                      enableVibration: true,
                    )),
                  ),
                  _FeatureBtn(
                    icon: Icons.timer_rounded,
                    label: '10s Timeout',
                    color: const Color(0xFFFF3B30),
                    onTap: () => _open(context, const ScannerConfig(
                      scanMode: ScanMode.single,
                      scanTimeout: Duration(seconds: 10),
                      enableVibration: true,
                    )),
                  ),
                  _FeatureBtn(
                    icon: Icons.camera_front_rounded,
                    label: 'Front Camera',
                    color: const Color(0xFF0066FF),
                    onTap: () => _open(context, const ScannerConfig(
                      scanMode: ScanMode.single,
                      cameraFacing: CameraFacing.front,
                      enableVibration: true,
                    )),
                  ),
                  _FeatureBtn(
                    icon: Icons.history_rounded,
                    label: 'History',
                    color: const Color(0xFF5856D6),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const HistoryScreen()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Themes ───────────────────────────────────────────────────
              const _SectionTitle('Scanner Themes'),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _ThemeBtn(
                      label: 'Neon',
                      color: const Color(0xFF00E5FF),
                      theme: ScannerTheme.neon,
                      onTap: (t) => _openWithTheme(context, t),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ThemeBtn(
                      label: 'Light',
                      color: const Color(0xFFFF9500),
                      theme: ScannerTheme.light,
                      onTap: (t) => _openWithTheme(context, t),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ThemeBtn(
                      label: 'Minimal',
                      color: const Color(0xFF8E8E93),
                      theme: ScannerTheme.minimal,
                      onTap: (t) => _openWithTheme(context, t),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, ScannerConfig config) => Navigator.push(
        context,
        _scannerRoute(ScannerScreen(config: config)),
      );

  void _openWithTheme(BuildContext context, ScannerTheme theme) =>
      Navigator.push(
        context,
        _scannerRoute(ScannerScreen(
          config: const ScannerConfig(
              scanMode: ScanMode.single,
              enableVibration: true,
              enableSound: true),
          theme: theme,
        )),
      );

  PageRouteBuilder<void> _scannerRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        transitionsBuilder: (_, animation, __, child) {
          final slide = Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
          final fade = Tween(begin: 0.0, end: 1.0)
              .animate(CurvedAnimation(parent: animation, curve: const Interval(0, 0.4)));
          return SlideTransition(
            position: slide,
            child: FadeTransition(opacity: fade, child: child),
          );
        },
      );
}

// ── Main scan button ──────────────────────────────────────────────────────────

class _MainScanBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _MainScanBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF0066FF),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0066FF).withAlpha(70),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Start Scanning',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    )),
                Text('QR codes & barcodes',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
            const Spacer(),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Feature grid button ───────────────────────────────────────────────────────

class _FeatureBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _FeatureBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF111111),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Theme button ──────────────────────────────────────────────────────────────

class _ThemeBtn extends StatelessWidget {
  final String label;
  final Color color;
  final ScannerTheme theme;
  final void Function(ScannerTheme) onTap;
  const _ThemeBtn(
      {required this.label,
      required this.color,
      required this.theme,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(theme),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withAlpha(100), blurRadius: 8)
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF111111),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF111111),
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    );
  }
}
