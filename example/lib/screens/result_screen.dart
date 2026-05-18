import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_qr_scanner/smart_qr_scanner.dart';
import 'scanner_screen.dart';

class ResultScreen extends StatefulWidget {
  final SmartScanResult result;
  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkCtrl;
  late Animation<double> _checkScale;
  late Animation<double> _checkFade;

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _checkScale = CurvedAnimation(
        parent: _checkCtrl, curve: const Interval(0, 0.7, curve: Curves.elasticOut));
    _checkFade = CurvedAnimation(
        parent: _checkCtrl, curve: const Interval(0, 0.4, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Ambient glow
          Positioned(
            top: -100,
            left: MediaQuery.of(context).size.width / 2 - 150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00E676).withAlpha(40),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        _buildSuccessBadge(),
                        const SizedBox(height: 28),
                        _buildResultCard(),
                        const SizedBox(height: 16),
                        _buildMetaCard(),
                        const SizedBox(height: 28),
                        _buildActions(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
          const Expanded(
            child: Text(
              'Scan Result',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildSuccessBadge() {
    return AnimatedBuilder(
      animation: _checkCtrl,
      builder: (_, __) => FadeTransition(
        opacity: _checkFade,
        child: Column(
          children: [
            Transform.scale(
              scale: _checkScale.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF00E676).withAlpha(40),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF00E676), Color(0xFF00C853)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E676).withAlpha(100),
                          blurRadius: 30,
                          spreadRadius: 0,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child:
                        const Icon(Icons.check_rounded, color: Colors.white, size: 44),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Scan Successful!',
              style: TextStyle(
                color: Color(0xFF00E676),
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(widget.result.timestamp),
              style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 13),
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
        color: const Color(0xFF16161F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: const Color(0xFF00E5FF).withAlpha(40), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header strip
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00E5FF).withAlpha(20),
                  const Color(0xFF7B2FFF).withAlpha(10),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.qr_code_2_rounded,
                      color: Color(0xFF00E5FF), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.result.typeName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: -0.2),
                      ),
                      Text(
                        widget.result.formatName,
                        style: TextStyle(
                            color: Colors.white.withAlpha(120), fontSize: 12),
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
                Text('Raw Value',
                    style: TextStyle(
                        color: Colors.white.withAlpha(100),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(60),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: Colors.white.withAlpha(15), width: 1),
                  ),
                  child: SelectableText(
                    widget.result.rawValue,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.6,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                if (widget.result.displayValue != null &&
                    widget.result.displayValue != widget.result.rawValue) ...[
                  const SizedBox(height: 14),
                  Text('Display Value',
                      style: TextStyle(
                          color: Colors.white.withAlpha(100),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Text(
                    widget.result.displayValue!,
                    style: const TextStyle(
                        color: Color(0xFF00E5FF), fontSize: 14, height: 1.5),
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
        ('Confidence',
            '${(widget.result.confidence! * 100).toStringAsFixed(0)}%'),
      ...widget.result.metadata.entries.map((e) => (
            e.key[0].toUpperCase() + e.key.substring(1),
            e.value?.toString() ?? '—',
          )),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF16161F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(12), width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Details',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: -0.2)),
          const SizedBox(height: 16),
          for (int i = 0; i < entries.length; i++) ...[
            _metaRow(entries[i].$1, entries[i].$2),
            if (i < entries.length - 1)
              Divider(color: Colors.white.withAlpha(10), height: 1),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        _PrimaryButton(
          icon: Icons.copy_all_rounded,
          label: 'Copy to Clipboard',
          gradient: const LinearGradient(
            colors: [Color(0xFF00B4D8), Color(0xFF00E5FF)],
          ),
          glowColor: const Color(0xFF00E5FF),
          onTap: () {
            Clipboard.setData(ClipboardData(text: widget.result.rawValue));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 18),
                  SizedBox(width: 10),
                  Text('Copied to clipboard'),
                ]),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _SecondaryButton(
          icon: Icons.qr_code_scanner_rounded,
          label: 'Scan Another',
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
        ? const Color(0xFF00E676)
        : confidence > 0.7
            ? const Color(0xFFFFB703)
            : const Color(0xFFFF6B6B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80), width: 1),
      ),
      child: Text('$pct%',
          style:
              TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Widget _metaRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(label,
                  style: TextStyle(
                      color: Colors.white.withAlpha(120), fontSize: 13)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
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

class _PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final Color glowColor;
  final VoidCallback onTap;
  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.glowColor,
    required this.onTap,
  });

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
              color: glowColor.withAlpha(80),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black, size: 22),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: -0.2)),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SecondaryButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(20), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: -0.2)),
          ],
        ),
      ),
    );
  }
}
