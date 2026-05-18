import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../controllers/scanner_controller.dart';
import '../models/scan_result.dart';
import '../models/scanner_theme.dart';
import '../services/permission_service.dart';
import 'components/scan_controls.dart';
import 'components/scan_success_animation.dart';
import 'painters/scanner_overlay_painter.dart';

class SmartScannerWidget extends StatefulWidget {
  final SmartQrScannerController controller;
  final ScannerTheme theme;
  final String hintText;
  final bool showControls;
  final bool showHint;
  final bool showFlash;
  final bool showGallery;
  final bool showFlip;
  final bool showMenu;
  final ValueChanged<ScannerTheme>? onThemeChanged;
  final Widget? errorWidget;
  final Widget? loadingWidget;

  const SmartScannerWidget({
    super.key,
    required this.controller,
    this.theme = ScannerTheme.neon,
    this.hintText = 'Align QR code within the frame',
    this.showControls = true,
    this.showHint = true,
    this.showFlash = true,
    this.showGallery = true,
    this.showFlip = true,
    this.showMenu = true,
    this.onThemeChanged,
    this.errorWidget,
    this.loadingWidget,
  });

  @override
  State<SmartScannerWidget> createState() => SmartScannerWidgetState();
}

class SmartScannerWidgetState extends State<SmartScannerWidget>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  late AnimationController _scanLineCtrl;
  late Animation<double> _scanLineAnim;

  late AnimationController _boxFadeCtrl;

  late AnimationController _statusCtrl;
  late Animation<double> _statusAnim;

  bool _showSuccess = false;
  bool _detecting = false;

  StreamSubscription<SmartScanResult>? _scanSub;
  StreamSubscription<List<SmartScanResult>>? _rawSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: widget.theme.scanLineAnimationDuration,
    )..repeat();
    _scanLineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut),
    );

    _boxFadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _statusCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _statusAnim = CurvedAnimation(parent: _statusCtrl, curve: Curves.easeOut);

    _scanSub = widget.controller.scanEvents.listen((_) {
      if (mounted) setState(() => _showSuccess = true);
    });

    _rawSub = widget.controller.rawScanEvents.listen((results) {
      if (!mounted) return;
      setState(() => _detecting = true);
      _statusCtrl.forward();
      _boxFadeCtrl.reset();
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          _statusCtrl.reverse();
          _boxFadeCtrl.forward();
          setState(() => _detecting = false);
        }
      });
    });

    if (!widget.controller.isInitialized) {
      widget.controller.initialize();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.controller.isInitialized) return;
    if (state == AppLifecycleState.paused) {
      widget.controller.pause();
    } else if (state == AppLifecycleState.resumed) {
      widget.controller.resume();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanLineCtrl.dispose();
    _boxFadeCtrl.dispose();
    _statusCtrl.dispose();
    _scanSub?.cancel();
    _rawSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final ctrl = widget.controller;
        if (ctrl.errorMessage != null) return _buildError(ctrl.errorMessage!);
        if (!ctrl.isInitialized) return _buildLoading();
        if (ctrl.permissionStatus == CameraPermissionStatus.permanentlyDenied) {
          return _buildPermissionDenied();
        }
        return _buildScanner(ctrl);
      },
    );
  }

  Widget _buildScanner(SmartQrScannerController ctrl) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);

      final scanW = size.width * ctrl.config.scanAreaWidthFactor;
      final scanH = size.height * ctrl.config.scanAreaHeightFactor;
      final scanRect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.42),
        width: scanW,
        height: scanH,
      );

      return Stack(children: [
        // 1. Full-screen camera feed (black placeholder while switching)
        Positioned.fill(
          child: ctrl.isSwitching
              ? const ColoredBox(color: Colors.black)
              : _CameraPreview(ctrl.cameraController!),
        ),

        // 2. Edge vignette + corner brackets
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _scanLineAnim,
            builder: (_, __) => CustomPaint(
              painter: ScannerOverlayPainter(
                scanRect: scanRect,
                theme: widget.theme,
                scanLineProgress: _scanLineAnim.value,
                detecting: _detecting,
              ),
            ),
          ),
        ),

        // 3. Status label above scan area
        Positioned(
          left: 0,
          right: 0,
          top: scanRect.top - 56,
          child: FadeTransition(
            opacity: _statusAnim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.4),
                end: Offset.zero,
              ).animate(_statusAnim),
              child: Center(
                child: _StatusLabel(
                  detecting: _detecting,
                  paused: ctrl.isPaused,
                  theme: widget.theme,
                ),
              ),
            ),
          ),
        ),

        // 4. Hint text below scan area
        if (widget.showHint)
          Positioned(
            left: 24,
            right: 24,
            top: scanRect.bottom + 20,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                ctrl.isPaused
                    ? 'Scanning paused'
                    : (_detecting
                        ? 'Hold steady while verifying...'
                        : widget.hintText),
                key: ValueKey(ctrl.isPaused ? 'p' : _detecting ? 'd' : 'i'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withAlpha(180),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                  height: 1.4,
                ),
              ),
            ),
          ),

        // 5. Paused overlay
        if (ctrl.isPaused) const Positioned.fill(child: _PausedOverlay()),

        // 6. Controls
        if (widget.showControls)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ScanControls(
              controller: ctrl,
              theme: widget.theme,
              showFlash: widget.showFlash,
              showGallery: widget.showGallery,
              showFlip: widget.showFlip,
            ),
          ),

        // 7. Success animation
        if (_showSuccess)
          Positioned.fill(
            child: ScanSuccessAnimation(
              theme: widget.theme,
              onComplete: () {
                if (mounted) setState(() => _showSuccess = false);
              },
            ),
          ),

        // 8. Menu button — placed in a kToolbarHeight row starting at the
        //    physical status-bar bottom (viewPadding, not padding which is
        //    inflated by the Scaffold when extendBodyBehindAppBar=true).
        if (widget.showMenu)
          Positioned(
            top: MediaQuery.of(context).viewPadding.top,
            left: 0,
            right: 0,
            height: kToolbarHeight,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _MenuBtn(onTap: _showThemePicker),
              ),
            ),
          ),
      ]);
    });
  }

  void showThemePicker() => _showThemePicker();

  void _showThemePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ThemeSheet(
        current: widget.theme,
        onSelect: (ScannerTheme t) {
          widget.onThemeChanged?.call(t);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildLoading() =>
      widget.loadingWidget ?? _LoadingScreen(theme: widget.theme);

  Widget _buildError(String message) =>
      widget.errorWidget ??
      _FullScreenState(
        icon: Icons.error_outline_rounded,
        iconColor: const Color(0xFFFF6B6B),
        title: 'Camera Error',
        subtitle: message,
        child: null,
      );

  Widget _buildPermissionDenied() => _FullScreenState(
        icon: Icons.camera_alt_outlined,
        iconColor: Colors.white54,
        title: 'Camera Access Required',
        subtitle: 'Please enable camera access in\nSettings to scan codes.',
        child: _SettingsButton(theme: widget.theme),
      );
}

// ── Camera preview ────────────────────────────────────────────────────────────

class _CameraPreview extends StatelessWidget {
  final CameraController controller;
  const _CameraPreview(this.controller);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeIn,
      builder: (_, opacity, child) => Opacity(opacity: opacity, child: child),
      child: ValueListenableBuilder<CameraValue>(
        valueListenable: controller,
        builder: (_, value, __) {
          if (!value.isInitialized) {
            return const ColoredBox(color: Colors.black);
          }
          return SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: value.previewSize?.height ?? 1,
                height: value.previewSize?.width ?? 1,
                child: CameraPreview(controller),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Status label (above scan area) ───────────────────────────────────────────

class _StatusLabel extends StatelessWidget {
  final bool detecting;
  final bool paused;
  final ScannerTheme theme;
  const _StatusLabel(
      {required this.detecting, required this.paused, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (!detecting && !paused) return const SizedBox.shrink();
    final color =
        paused ? Colors.orange : theme.successColor;
    final text = paused ? 'Scanning paused' : 'Code detected — verifying...';
    final icon =
        paused ? Icons.pause_circle_outline_rounded : Icons.qr_code_scanner_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withAlpha(100)),
        boxShadow: [BoxShadow(color: color.withAlpha(40), blurRadius: 14)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Paused overlay ────────────────────────────────────────────────────────────

class _PausedOverlay extends StatelessWidget {
  const _PausedOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withAlpha(80),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(15),
                border:
                    Border.all(color: Colors.white.withAlpha(40)),
              ),
              child: const Icon(Icons.pause_rounded,
                  color: Colors.white70, size: 34),
            ),
            const SizedBox(height: 16),
            const Text(
              'Scanning Paused',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loading screen ────────────────────────────────────────────────────────────

class _LoadingScreen extends StatefulWidget {
  final ScannerTheme theme;
  const _LoadingScreen({required this.theme});

  @override
  State<_LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<_LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.theme.borderColor;
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => CustomPaint(
                  painter: _LoadingFramePainter(
                      accent: accent, progress: _ctrl.value),
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Starting camera…',
              style: TextStyle(
                color: Colors.white.withAlpha(200),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingFramePainter extends CustomPainter {
  final Color accent;
  final double progress;
  const _LoadingFramePainter({required this.accent, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(12, 12, size.width - 24, size.height - 24);
    const r = 14.0;
    const len = 26.0;
    const sw = 3.0;

    final alpha = (math.sin(progress * math.pi) * 180 + 75).round();
    final paint = Paint()
      ..color = accent.withAlpha(alpha)
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    void corner(double x, double y, double sx, double sy) {
      final path = Path()
        ..moveTo(x + r * sx, y)
        ..arcToPoint(Offset(x, y + r * sy),
            radius: const Radius.circular(r), clockwise: sx != sy)
        ..moveTo(x + r * sx, y)
        ..lineTo(x + (r + len) * sx, y)
        ..moveTo(x, y + r * sy)
        ..lineTo(x, y + (r + len) * sy);
      canvas.drawPath(path, paint);
    }

    corner(rect.left, rect.top, 1, 1);
    corner(rect.right, rect.top, -1, 1);
    corner(rect.left, rect.bottom, 1, -1);
    corner(rect.right, rect.bottom, -1, -1);
  }

  @override
  bool shouldRepaint(_LoadingFramePainter old) => old.progress != progress;
}

// ── Full-screen state (error / permission) ────────────────────────────────────

class _FullScreenState extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? child;

  const _FullScreenState({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withAlpha(15),
                border: Border.all(color: iconColor.withAlpha(60)),
              ),
              child: Icon(icon, color: iconColor, size: 38),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withAlpha(140),
                fontSize: 14,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            if (child != null) ...[
              const SizedBox(height: 32),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}

// ── Menu button (3-dots, top-right of scanner) ───────────────────────────────

class _MenuBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _MenuBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withAlpha(110),
              border: Border.all(color: Colors.white.withAlpha(30)),
            ),
            child: const Icon(Icons.more_vert_rounded,
                color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

// ── Theme picker bottom sheet ─────────────────────────────────────────────────

class _ThemeSheet extends StatelessWidget {
  final ScannerTheme current;
  final ValueChanged<ScannerTheme> onSelect;
  const _ThemeSheet({required this.current, required this.onSelect});

  static const _options = [
    (
      theme: ScannerTheme.neon,
      label: 'Neon',
      desc: 'Cyan glow with dark overlay',
      color: Color(0xFF00E5FF),
      icon: Icons.electric_bolt_rounded,
    ),
    (
      theme: ScannerTheme.light,
      label: 'Light',
      desc: 'Warm amber, clean & subtle',
      color: Color(0xFFFFB703),
      icon: Icons.wb_sunny_rounded,
    ),
    (
      theme: ScannerTheme.minimal,
      label: 'Minimal',
      desc: 'Pure white, distraction-free',
      color: Color(0xFF607D8B),
      icon: Icons.layers_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      margin: EdgeInsets.fromLTRB(12, 0, 12, bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 40,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 14, bottom: 4),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(20),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black.withAlpha(15)),
                  ),
                  child: Icon(Icons.palette_outlined,
                      color: Colors.black.withAlpha(160), size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Scanner Theme',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.close_rounded,
                        color: Colors.black.withAlpha(120), size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Theme options
          for (final o in _options)
            _ThemeOption(
              theme: o.theme,
              label: o.label,
              desc: o.desc,
              color: o.color,
              icon: o.icon,
              selected: current == o.theme,
              onTap: () => onSelect(o.theme),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final ScannerTheme theme;
  final String label;
  final String desc;
  final Color color;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.theme,
    required this.label,
    required this.desc,
    required this.color,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(18) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color.withAlpha(80) : Colors.black.withAlpha(15),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            // Icon container
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withAlpha(selected ? 28 : 14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: color.withAlpha(selected ? 120 : 40),
                  width: 1,
                ),
                boxShadow: selected
                    ? [BoxShadow(color: color.withAlpha(60), blurRadius: 12)]
                    : [],
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            // Labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? color : Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: TextStyle(
                      color: Colors.black.withAlpha(100),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            // Checkmark
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: selected
                  ? Container(
                      key: const ValueKey('check'),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: color.withAlpha(100), blurRadius: 8)
                        ],
                      ),
                      child:
                          const Icon(Icons.check_rounded, color: Colors.black, size: 14),
                    )
                  : const SizedBox(key: ValueKey('empty'), width: 26, height: 26),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Settings button ───────────────────────────────────────────────────────────

class _SettingsButton extends StatelessWidget {
  final ScannerTheme theme;
  const _SettingsButton({required this.theme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: PermissionService.openSettings,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: theme.borderColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: theme.borderColor.withAlpha(80),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.settings_rounded, color: Colors.black, size: 18),
            SizedBox(width: 8),
            Text(
              'Open Settings',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
