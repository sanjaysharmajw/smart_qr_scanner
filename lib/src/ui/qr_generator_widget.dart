import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

/// Barcode type for QR generation.
enum QrInputType { text, url, wifi, email, phone, contact }

/// A full-featured QR code generator widget.
/// Supports text, URL, WiFi, email, phone, and contact card input types.
/// Renders QR codes using a custom [CustomPainter] — no qr_flutter dependency.
class QrGeneratorWidget extends StatefulWidget {
  /// Called when a QR is successfully generated. Receives the raw data string.
  final ValueChanged<String>? onGenerated;

  /// Accent color for buttons, active state, and QR eye modules.
  final Color accentColor;

  const QrGeneratorWidget({
    super.key,
    this.onGenerated,
    this.accentColor = const Color(0xFF7C4DFF),
  });

  @override
  State<QrGeneratorWidget> createState() => _QrGeneratorWidgetState();
}

class _QrGeneratorWidgetState extends State<QrGeneratorWidget>
    with SingleTickerProviderStateMixin {
  QrInputType _type = QrInputType.url;
  String _qrData = '';

  final _textCtrl         = TextEditingController();
  final _urlCtrl          = TextEditingController();
  final _emailCtrl        = TextEditingController();
  final _phoneCtrl        = TextEditingController();
  final _ssidCtrl         = TextEditingController();
  final _passCtrl         = TextEditingController();
  final _nameCtrl         = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  final _contactEmailCtrl = TextEditingController();
  String _wifiSec = 'WPA';

  late AnimationController _qrFadeCtrl;
  late Animation<double> _qrFade;

  @override
  void initState() {
    super.initState();
    _qrFadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _qrFade = CurvedAnimation(parent: _qrFadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _qrFadeCtrl.dispose();
    _textCtrl.dispose();        _urlCtrl.dispose();
    _emailCtrl.dispose();       _phoneCtrl.dispose();
    _ssidCtrl.dispose();        _passCtrl.dispose();
    _nameCtrl.dispose();        _contactPhoneCtrl.dispose();
    _contactEmailCtrl.dispose();
    super.dispose();
  }

  void _generate() {
    final data = _buildData();
    if (data.isEmpty) return;
    setState(() => _qrData = data);
    _qrFadeCtrl.forward(from: 0);
    widget.onGenerated?.call(data);
  }

  String _buildData() {
    switch (_type) {
      case QrInputType.text:
        return _textCtrl.text.trim();
      case QrInputType.url:
        final url = _urlCtrl.text.trim();
        if (url.isEmpty) return '';
        return url.startsWith('http') ? url : 'https://$url';
      case QrInputType.email:
        final e = _emailCtrl.text.trim();
        return e.isEmpty ? '' : 'mailto:$e';
      case QrInputType.phone:
        final p = _phoneCtrl.text.trim();
        return p.isEmpty ? '' : 'tel:$p';
      case QrInputType.wifi:
        final s = _ssidCtrl.text.trim();
        if (s.isEmpty) return '';
        return 'WIFI:T:$_wifiSec;S:$s;P:${_passCtrl.text};;';
      case QrInputType.contact:
        final name = _nameCtrl.text.trim();
        if (name.isEmpty) return '';
        return 'BEGIN:VCARD\nVERSION:3.0\nFN:$name\n'
            '${_contactPhoneCtrl.text.isNotEmpty ? 'TEL:${_contactPhoneCtrl.text}\n' : ''}'
            '${_contactEmailCtrl.text.isNotEmpty ? 'EMAIL:${_contactEmailCtrl.text}\n' : ''}'
            'END:VCARD';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TypeSelector(
          selected: _type,
          accent: widget.accentColor,
          onChanged: (t) => setState(() {
            _type = t;
            _qrData = '';
            _qrFadeCtrl.reset();
          }),
        ),
        const SizedBox(height: 20),
        _buildInputs(),
        const SizedBox(height: 20),
        _GenerateButton(accent: widget.accentColor, onTap: _generate),
        if (_qrData.isNotEmpty) ...[
          const SizedBox(height: 28),
          FadeTransition(
            opacity: _qrFade,
            child: _QrDisplay(data: _qrData, accent: widget.accentColor),
          ),
        ],
      ],
    );
  }

  Widget _buildInputs() {
    switch (_type) {
      case QrInputType.text:
        return _Field(ctrl: _textCtrl,  label: 'Text',           hint: 'Enter any text…',      icon: Icons.text_fields_rounded,     maxLines: 3);
      case QrInputType.url:
        return _Field(ctrl: _urlCtrl,   label: 'URL',            hint: 'example.com',           icon: Icons.link_rounded,            keyboardType: TextInputType.url);
      case QrInputType.email:
        return _Field(ctrl: _emailCtrl, label: 'Email Address',  hint: 'user@example.com',      icon: Icons.email_outlined,          keyboardType: TextInputType.emailAddress);
      case QrInputType.phone:
        return _Field(ctrl: _phoneCtrl, label: 'Phone Number',   hint: '+91 98765 43210',       icon: Icons.phone_outlined,          keyboardType: TextInputType.phone);
      case QrInputType.wifi:
        return _WifiFields(ssidCtrl: _ssidCtrl, passCtrl: _passCtrl, security: _wifiSec, onSecurityChanged: (s) => setState(() => _wifiSec = s));
      case QrInputType.contact:
        return _ContactFields(nameCtrl: _nameCtrl, phoneCtrl: _contactPhoneCtrl, emailCtrl: _contactEmailCtrl);
    }
  }
}

/// A widget that renders a QR code for [data] using [PrettyQrView].
/// Shows an error placeholder if the data cannot be encoded.
class QrView extends StatelessWidget {
  final String data;
  final double size;
  final Color eyeColor;
  final Color dataColor;
  final Color background;

  const QrView({
    super.key,
    required this.data,
    this.size       = 220,
    this.eyeColor   = Colors.black,
    this.dataColor  = Colors.black,
    this.background = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: PrettyQrView.data(
        data: data,
        decoration: PrettyQrDecoration(
          shape: PrettyQrSquaresSymbol(color: dataColor),
          background: background,
          quietZone: PrettyQrQuietZone.standard,
        ),
        errorBuilder: (_, __, ___) => Center(
          child: Text(
            'Data too large\nfor a QR code',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ),
      ),
    );
  }
}

// ── Type selector chips ───────────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  final QrInputType selected;
  final Color accent;
  final ValueChanged<QrInputType> onChanged;
  const _TypeSelector({required this.selected, required this.accent, required this.onChanged});

  static const _types = [
    (type: QrInputType.url,     label: 'URL',     icon: Icons.link_rounded),
    (type: QrInputType.text,    label: 'Text',    icon: Icons.text_fields_rounded),
    (type: QrInputType.wifi,    label: 'WiFi',    icon: Icons.wifi_rounded),
    (type: QrInputType.email,   label: 'Email',   icon: Icons.email_outlined),
    (type: QrInputType.phone,   label: 'Phone',   icon: Icons.phone_outlined),
    (type: QrInputType.contact, label: 'Contact', icon: Icons.person_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final t = _types[i];
          final active = selected == t.type;
          return GestureDetector(
            onTap: () => onChanged(t.type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: active ? accent : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: active ? accent : const Color(0xFFE0E0E0)),
                boxShadow: active ? [BoxShadow(color: accent.withAlpha(60), blurRadius: 8)] : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(t.icon, size: 15, color: active ? Colors.white : Colors.black54),
                  const SizedBox(width: 6),
                  Text(t.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : Colors.black87)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Input fields ──────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final IconData icon;
  final TextInputType keyboardType;
  final int maxLines;

  const _Field({
    required this.ctrl, required this.label, required this.hint, required this.icon,
    this.keyboardType = TextInputType.text, this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _WifiFields extends StatelessWidget {
  final TextEditingController ssidCtrl, passCtrl;
  final String security;
  final ValueChanged<String> onSecurityChanged;
  const _WifiFields({required this.ssidCtrl, required this.passCtrl, required this.security, required this.onSecurityChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Field(ctrl: ssidCtrl, label: 'Network Name (SSID)', hint: 'MyWiFi', icon: Icons.wifi_rounded),
        const SizedBox(height: 12),
        _Field(ctrl: passCtrl, label: 'Password', hint: '••••••••', icon: Icons.lock_outline_rounded, keyboardType: TextInputType.visiblePassword),
        const SizedBox(height: 12),
        Row(
          children: ['WPA', 'WEP', 'None'].map((s) {
            final active = security == s;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSecurityChanged(s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFF7C4DFF) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: active ? const Color(0xFF7C4DFF) : const Color(0xFFE0E0E0)),
                  ),
                  child: Text(s, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: active ? Colors.white : Colors.black87)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ContactFields extends StatelessWidget {
  final TextEditingController nameCtrl, phoneCtrl, emailCtrl;
  const _ContactFields({required this.nameCtrl, required this.phoneCtrl, required this.emailCtrl});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _Field(ctrl: nameCtrl,  label: 'Full Name',          hint: 'John Doe',         icon: Icons.person_outline_rounded),
      const SizedBox(height: 12),
      _Field(ctrl: phoneCtrl, label: 'Phone (optional)',   hint: '+91 98765 43210',  icon: Icons.phone_outlined,         keyboardType: TextInputType.phone),
      const SizedBox(height: 12),
      _Field(ctrl: emailCtrl, label: 'Email (optional)',   hint: 'john@example.com', icon: Icons.email_outlined,         keyboardType: TextInputType.emailAddress),
    ],
  );
}

// ── Generate button ───────────────────────────────────────────────────────────

class _GenerateButton extends StatelessWidget {
  final Color accent;
  final VoidCallback onTap;
  const _GenerateButton({required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [accent, Color.lerp(accent, Colors.black, 0.15)!]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: accent.withAlpha(80), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_rounded, color: Colors.white, size: 20),
          SizedBox(width: 10),
          Text('Generate QR Code', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
        ],
      ),
    ),
  );
}

// ── QR display card ───────────────────────────────────────────────────────────

class _QrDisplay extends StatefulWidget {
  final String data;
  final Color accent;
  const _QrDisplay({required this.data, required this.accent});

  @override
  State<_QrDisplay> createState() => _QrDisplayState();
}

class _QrDisplayState extends State<_QrDisplay> {
  final _qrKey = GlobalKey();
  bool _saving = false;

  /// Renders the QR widget to a PNG [Uint8List] at 3× pixel ratio.
  Future<Uint8List?> _captureQr() async {
    try {
      final boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _download() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final bytes = await _captureQr();
      if (bytes == null || !mounted) return;

      // Request gallery permission if not already granted.
      if (!await Gal.hasAccess()) {
        final granted = await Gal.requestAccess();
        if (!granted || !mounted) return;
      }

      final ts = DateTime.now().millisecondsSinceEpoch;
      await Gal.putImageBytes(bytes, name: 'qr_$ts.png');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_rounded,
                color: Color(0xFF00E676), size: 18),
            SizedBox(width: 10),
            Text('Saved to Gallery'),
          ]),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(18),
              blurRadius: 24,
              offset: const Offset(0, 8))
        ],
        border: Border.all(color: Colors.black.withAlpha(8)),
      ),
      child: Column(
        children: [
          // QR code wrapped in RepaintBoundary for image capture
          RepaintBoundary(
            key: _qrKey,
            child: QrView(
              data: widget.data,
              eyeColor: widget.accent,
            ),
          ),
          const SizedBox(height: 20),
          // Data preview
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.data.length > 60
                  ? '${widget.data.substring(0, 60)}…'
                  : widget.data,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontFamily: 'monospace'),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          // Copy + Download row
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  icon: Icons.copy_rounded,
                  label: 'Copy',
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: widget.data));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Copied to clipboard'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionBtn(
                  icon: _saving
                      ? Icons.hourglass_top_rounded
                      : Icons.download_rounded,
                  label: _saving ? 'Saving…' : 'Download',
                  onTap: _download,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.black87),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}
