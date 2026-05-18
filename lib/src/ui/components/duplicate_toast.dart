import 'dart:async';
import 'package:flutter/material.dart';

/// An overlay toast shown when a duplicate scan is detected.
/// Insert [DuplicateToastOverlay] into your widget tree and call
/// [DuplicateToastOverlay.show] to trigger it.
class DuplicateToastOverlay extends StatefulWidget {
  final Widget child;
  const DuplicateToastOverlay({super.key, required this.child});

  /// Shows the duplicate toast via the nearest [DuplicateToastOverlay].
  static void show(BuildContext context, {String? message}) {
    _DuplicateToastOverlayState? state =
        context.findAncestorStateOfType<_DuplicateToastOverlayState>();
    state?._show(message ?? 'Already scanned');
  }

  @override
  State<DuplicateToastOverlay> createState() => _DuplicateToastOverlayState();
}

class _DuplicateToastOverlayState extends State<DuplicateToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  String _message = 'Already scanned';
  Timer? _hideTimer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  void _show(String message) {
    if (!mounted) return;
    _hideTimer?.cancel();
    setState(() {
      _message = message;
      _visible = true;
    });
    _ctrl.forward(from: 0);
    _hideTimer = Timer(const Duration(seconds: 2), _hide);
  }

  void _hide() {
    _ctrl.reverse().then((_) {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_visible)
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: FadeTransition(
                opacity: _opacity,
                child: _Toast(message: _message),
              ),
            ),
          ),
      ],
    );
  }
}

class _Toast extends StatelessWidget {
  final String message;
  const _Toast({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.copy, color: Colors.amber, size: 16),
          const SizedBox(width: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
