import 'package:flutter/material.dart';
import 'package:smart_qr_scanner/smart_qr_scanner.dart';
import '../widgets/holographic_qr_overlay.dart';
import 'result_screen.dart';

class ScannerScreen extends StatefulWidget {
  final ScannerConfig config;
  final ScannerTheme theme;
  final void Function(SmartScanResult)? onResult;
  final SmartQrScannerController? controller;

  const ScannerScreen({
    super.key,
    this.config = const ScannerConfig(
      scanMode: ScanMode.single,
      enableVibration: true,
    ),
    this.theme = ScannerTheme.light,
    this.onResult,
    this.controller,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  late SmartQrScannerController _controller;
  late ScannerTheme _theme;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  final _scannerKey = GlobalKey<SmartScannerWidgetState>();

  @override
  void initState() {
    super.initState();
    _theme = widget.theme;
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _controller =
        widget.controller ?? SmartQrScannerController(config: widget.config);
    _controller.onScan = (result) => widget.onResult?.call(result);
    _controller.onTimeout = _onTimeout;
    _controller.onError = _onError;
    if (widget.controller == null) _controller.initialize();
  }

  void _navigateToResult(SmartScanResult result) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => ResultScreen(result: result),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _onTimeout() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(children: [
        Icon(Icons.timer_off_rounded, color: Colors.white, size: 18),
        SizedBox(width: 10),
        Text('Scan timed out. Please try again.'),
      ]),
      backgroundColor: const Color(0xFFFF9800),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
    Navigator.pop(context);
  }

  void _onError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ]),
      backgroundColor: const Color(0xFFE53935),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.chevron_left_rounded,
              color: Colors.white, size: 32),
        ),
        actions: [
          IconButton(
            onPressed: () => _scannerKey.currentState?.showThemePicker(),
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SmartScannerWidget(
          key: _scannerKey,
          controller: _controller,
          theme: _theme,
          hintText: 'Point camera at a QR code or barcode',
          showControls: true,
          showHint: true,
          showMenu: false,
          onThemeChanged: (t) => setState(() => _theme = t),
          // Hologram appears simultaneously with pixel burst (behind it).
          // onDismiss is null → SmartScannerWidget removes it via _showSuccess.
          successOverlayBuilder: (result) => HolographicQrOverlay(
            rawValue: result.rawValue,
          ),
          // Navigate only after the pixel burst animation completes.
          onScanAnimationComplete: _navigateToResult,
        ),
      ),
    );
  }
}
