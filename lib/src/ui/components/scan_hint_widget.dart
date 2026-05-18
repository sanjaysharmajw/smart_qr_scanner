import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/scanner_theme.dart';

/// Animated glassmorphism pill shown below the scan area with contextual hint.
class ScanHintWidget extends StatefulWidget {
  final String text;
  final ScannerTheme theme;

  const ScanHintWidget({
    super.key,
    required this.text,
    required this.theme,
  });

  @override
  State<ScanHintWidget> createState() => _ScanHintWidgetState();
}

class _ScanHintWidgetState extends State<ScanHintWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  String _displayText = '';

  @override
  void initState() {
    super.initState();
    _displayText = widget.text;
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(ScanHintWidget old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      setState(() => _displayText = widget.text);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPaused = _displayText == 'Paused';
    final accent = widget.theme.borderColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(isPaused ? 120 : 80),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: isPaused
                  ? Colors.orangeAccent.withAlpha(100)
                  : Colors.white.withAlpha(30),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing dot indicator
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPaused
                        ? Colors.orangeAccent
                            .withAlpha((_pulseAnim.value * 220).round())
                        : accent.withAlpha((_pulseAnim.value * 220).round()),
                    boxShadow: [
                      BoxShadow(
                        color: isPaused
                            ? Colors.orangeAccent
                                .withAlpha((_pulseAnim.value * 120).round())
                            : accent
                                .withAlpha((_pulseAnim.value * 120).round()),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: Text(
                  _displayText,
                  key: ValueKey(_displayText),
                  style: TextStyle(
                    color: isPaused ? Colors.orangeAccent : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
