import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_qr_scanner/smart_qr_scanner.dart';
import 'scanner_screen.dart';

// ── Design tokens (mirror home_screen) ───────────────────────────────────────
abstract final class _C {
  static const bg      = Color(0xFFF0F7FF);
  static const primary = Color(0xFF00BCD4);
  static const dark    = Color(0xFF00838F);
  static const text    = Color(0xFF1A1A2E);
  static const mid     = Color(0xFF6B7280);
  static const light   = Color(0xFFB0B8C4);
  static const border  = Color(0xFFE8EFF8);
  static const success = Color(0xFF00C48C);
  static const error   = Color(0xFFFF5B5B);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00BCD4), Color(0xFF006064)],
  );
}

class ResultScreen extends StatefulWidget {
  final SmartScanResult result;
  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _scale = CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.7, curve: Curves.elasticOut));
    _fade  = CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.4, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          _buildGradientHeader(context),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildSuccessBadge(),
                  const SizedBox(height: 24),
                  _buildResultCard(),
                  const SizedBox(height: 14),
                  _buildMetaCard(),
                  const SizedBox(height: 24),
                  _buildActions(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: _C.gradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withAlpha(50), width: 1),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                ),
              ),
              const Expanded(
                child: Text(
                  'Scan Result',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              FavoriteButton.forValue(
                widget.result.rawValue,
                activeColor: Colors.amber,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessBadge() {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => FadeTransition(
        opacity: _fade,
        child: Column(
          children: [
            Transform.scale(
              scale: _scale.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [_C.success.withAlpha(40), Colors.transparent],
                      ),
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF00C48C), Color(0xFF00A574)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _C.success.withAlpha(100),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Scan Successful!',
              style: TextStyle(
                color: _C.success,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(widget.result.timestamp),
              style: const TextStyle(color: _C.mid, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: _C.primary.withAlpha(20), blurRadius: 20, offset: const Offset(0, 6)),
          BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header strip
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_C.primary.withAlpha(18), _C.dark.withAlpha(10)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _C.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.qr_code_2_rounded, color: _C.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.result.typeName,
                        style: const TextStyle(
                          color: _C.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        widget.result.formatName,
                        style: const TextStyle(color: _C.mid, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (widget.result.confidence != null)
                  _confidencePill(widget.result.confidence!),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Raw Value',
                    style: TextStyle(
                        color: _C.light,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _C.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _C.border, width: 1),
                  ),
                  child: SelectableText(
                    widget.result.rawValue,
                    style: const TextStyle(
                      color: _C.text,
                      fontSize: 14,
                      height: 1.6,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                if (widget.result.displayValue != null &&
                    widget.result.displayValue != widget.result.rawValue) ...[
                  const SizedBox(height: 14),
                  const Text('Display Value',
                      style: TextStyle(
                          color: _C.light,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Text(
                    widget.result.displayValue!,
                    style: const TextStyle(color: _C.primary, fontSize: 14, height: 1.5),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaCard() {
    final entries = <(String, String)>[
      ('Format', widget.result.formatName),
      ('Type', widget.result.typeName),
      if (widget.result.confidence != null)
        ('Confidence', '${(widget.result.confidence! * 100).toStringAsFixed(0)}%'),
      ...widget.result.metadata.entries.map((e) => (
            e.key[0].toUpperCase() + e.key.substring(1),
            e.value?.toString() ?? '—',
          )),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Details',
              style: TextStyle(color: _C.text, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: -0.2)),
          const SizedBox(height: 14),
          for (int i = 0; i < entries.length; i++) ...[
            _metaRow(entries[i].$1, entries[i].$2),
            if (i < entries.length - 1)
              const Divider(color: _C.border, height: 1),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final canOpen = SmartUrlHandler.canHandle(widget.result);
    return Column(
      children: [
        _PrimaryBtn(
          icon: Icons.copy_all_rounded,
          label: 'Copy to Clipboard',
          gradient: _C.gradient,
          onTap: () {
            Clipboard.setData(ClipboardData(text: widget.result.rawValue));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(children: [
                  Icon(Icons.check_circle_rounded, color: _C.success, size: 18),
                  SizedBox(width: 10),
                  Text('Copied to clipboard'),
                ]),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            );
          },
        ),
        if (canOpen) ...[
          const SizedBox(height: 12),
          _PrimaryBtn(
            icon: Icons.open_in_new_rounded,
            label: SmartUrlHandler.actionLabel(widget.result),
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFFAB5CFA)],
            ),
            onTap: () => SmartUrlHandler.launch(widget.result),
          ),
        ],
        const SizedBox(height: 12),
        _SecondaryBtn(
          icon: Icons.qr_code_scanner_rounded,
          label: 'Scan Again',
          onTap: () => Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, anim, __) => const ScannerScreen(),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 350),
            ),
          ),
        ),
      ],
    );
  }

  Widget _confidencePill(double confidence) {
    final pct = (confidence * 100).toStringAsFixed(0);
    final color = confidence > 0.9
        ? _C.success
        : confidence > 0.7
            ? const Color(0xFFF59E0B)
            : _C.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80), width: 1),
      ),
      child: Text('$pct%',
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Widget _metaRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(label, style: const TextStyle(color: _C.mid, fontSize: 13)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(color: _C.text, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m  ${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Buttons ───────────────────────────────────────────────────────────────────

class _PrimaryBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;
  const _PrimaryBtn({required this.icon, required this.label, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withAlpha(80),
              blurRadius: 20,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: -0.2)),
          ],
        ),
      ),
    );
  }
}

class _SecondaryBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SecondaryBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 12, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _C.primary, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: _C.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: -0.2)),
          ],
        ),
      ),
    );
  }
}
