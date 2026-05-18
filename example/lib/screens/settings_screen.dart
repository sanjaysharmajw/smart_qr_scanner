import 'package:flutter/material.dart';
import 'package:smart_qr_scanner/smart_qr_scanner.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ScanMode _scanMode = ScanMode.single;
  bool _vibration = true;
  bool _sound = true;
  bool _boundingBox = true;
  bool _preventDuplicates = true;
  bool _autoFocus = true;
  bool _history = true;
  int _framesToSkip = 0;
  final List<BarcodeFormat> _selectedFormats = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                physics: const BouncingScrollPhysics(),
                children: [
                  _Section(
                    title: 'Scan Mode',
                    icon: Icons.radar_rounded,
                    iconColor: const Color(0xFF00E5FF),
                    child: _buildModeSelector(),
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    title: 'Feedback',
                    icon: Icons.notifications_active_rounded,
                    iconColor: const Color(0xFFFF9F1C),
                    child: Column(
                      children: [
                        _Toggle(
                          icon: Icons.vibration_rounded,
                          iconColor: const Color(0xFFFF9F1C),
                          title: 'Vibration',
                          subtitle: 'Haptic feedback on scan',
                          value: _vibration,
                          onChanged: (v) => setState(() => _vibration = v),
                        ),
                        _divider(),
                        _Toggle(
                          icon: Icons.volume_up_rounded,
                          iconColor: const Color(0xFF00E676),
                          title: 'Sound',
                          subtitle: 'Beep tone on scan',
                          value: _sound,
                          onChanged: (v) => setState(() => _sound = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    title: 'Detection',
                    icon: Icons.center_focus_strong_rounded,
                    iconColor: const Color(0xFF7B2FFF),
                    child: Column(
                      children: [
                        _Toggle(
                          icon: Icons.crop_free_rounded,
                          iconColor: const Color(0xFF7B2FFF),
                          title: 'Bounding Box',
                          subtitle: 'Draw highlight around detected code',
                          value: _boundingBox,
                          onChanged: (v) => setState(() => _boundingBox = v),
                        ),
                        _divider(),
                        _Toggle(
                          icon: Icons.block_rounded,
                          iconColor: const Color(0xFFFF6B6B),
                          title: 'Prevent Duplicates',
                          subtitle: 'Ignore repeated scans',
                          value: _preventDuplicates,
                          onChanged: (v) =>
                              setState(() => _preventDuplicates = v),
                        ),
                        _divider(),
                        _Toggle(
                          icon: Icons.center_focus_weak_rounded,
                          iconColor: const Color(0xFF00E5FF),
                          title: 'Auto Focus',
                          subtitle: 'Continuous autofocus',
                          value: _autoFocus,
                          onChanged: (v) => setState(() => _autoFocus = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    title: 'Performance',
                    icon: Icons.speed_rounded,
                    iconColor: const Color(0xFFFFB703),
                    child: _buildFrameSkip(),
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    title: 'History',
                    icon: Icons.history_rounded,
                    iconColor: const Color(0xFF00E676),
                    child: _Toggle(
                      icon: Icons.save_alt_rounded,
                      iconColor: const Color(0xFF00E676),
                      title: 'Save History',
                      subtitle: 'Store scan results locally',
                      value: _history,
                      onChanged: (v) => setState(() => _history = v),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    title: 'Barcode Formats',
                    icon: Icons.qr_code_rounded,
                    iconColor: const Color(0xFF00E5FF),
                    child: _buildFormats(),
                  ),
                  const SizedBox(height: 24),
                  _buildApplyButton(),
                ],
              ),
            ),
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
          const Text('Settings',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4)),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(40),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ModeSegment(
            label: 'Single',
            icon: Icons.touch_app_rounded,
            selected: _scanMode == ScanMode.single,
            onTap: () => setState(() => _scanMode = ScanMode.single),
          ),
          _ModeSegment(
            label: 'Continuous',
            icon: Icons.all_inclusive_rounded,
            selected: _scanMode == ScanMode.continuous,
            onTap: () => setState(() => _scanMode = ScanMode.continuous),
          ),
        ],
      ),
    );
  }

  Widget _buildFrameSkip() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.speed_rounded, color: Color(0xFFFFB703), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Frame Skip',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  Text(
                    _framesToSkip == 0
                        ? 'Process every frame'
                        : 'Skip $_framesToSkip frame${_framesToSkip > 1 ? 's' : ''} between scans',
                    style: TextStyle(
                        color: Colors.white.withAlpha(120), fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB703).withAlpha(25),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: const Color(0xFFFFB703).withAlpha(60)),
              ),
              child: Text(
                '$_framesToSkip',
                style: const TextStyle(
                    color: Color(0xFFFFB703),
                    fontWeight: FontWeight.w800,
                    fontSize: 15),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFFFB703),
            thumbColor: const Color(0xFFFFB703),
            inactiveTrackColor: Colors.white.withAlpha(15),
            overlayColor: const Color(0xFFFFB703).withAlpha(30),
            trackHeight: 4,
          ),
          child: Slider(
            value: _framesToSkip.toDouble(),
            min: 0,
            max: 5,
            divisions: 5,
            label: _framesToSkip.toString(),
            onChanged: (v) => setState(() => _framesToSkip = v.round()),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Fast', style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 11)),
            Text('Battery saver', style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildFormats() {
    final formats = [
      ('QR Code', BarcodeFormat.qrCode, const Color(0xFF00E5FF)),
      ('EAN-13', BarcodeFormat.ean13, const Color(0xFF00E676)),
      ('EAN-8', BarcodeFormat.ean8, const Color(0xFF00E676)),
      ('Code 128', BarcodeFormat.code128, const Color(0xFF7B2FFF)),
      ('Code 39', BarcodeFormat.code39, const Color(0xFF7B2FFF)),
      ('PDF417', BarcodeFormat.pdf417, const Color(0xFFFF9F1C)),
      ('Data Matrix', BarcodeFormat.dataMatrix, const Color(0xFFFF6B6B)),
      ('Aztec', BarcodeFormat.aztec, const Color(0xFFFFB703)),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: formats.map((f) {
        final selected =
            _selectedFormats.isEmpty || _selectedFormats.contains(f.$2);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (_selectedFormats.contains(f.$2)) {
                _selectedFormats.remove(f.$2);
              } else {
                _selectedFormats.add(f.$2);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? f.$3.withAlpha(25) : Colors.black.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? f.$3.withAlpha(120) : Colors.white.withAlpha(20),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(Icons.check_rounded, color: f.$3, size: 13),
                  ),
                Text(
                  f.$1,
                  style: TextStyle(
                    color: selected ? f.$3 : Colors.white.withAlpha(120),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildApplyButton() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 18),
              SizedBox(width: 10),
              Text('Settings saved successfully'),
            ]),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
        Navigator.pop(context);
      },
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00B4D8), Color(0xFF00E5FF)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withAlpha(80),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_rounded, color: Colors.black, size: 22),
            SizedBox(width: 10),
            Text('Save Settings',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: -0.2)),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Divider(
      color: Colors.white.withAlpha(12), height: 1, indent: 52, endIndent: 0);
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  const _Section({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, color: iconColor, size: 14),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      color: iconColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF16161F),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(10), width: 1),
          ),
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      color: Colors.white.withAlpha(100), fontSize: 12)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: iconColor,
          activeTrackColor: iconColor.withAlpha(50),
          inactiveThumbColor: Colors.white38,
          inactiveTrackColor: Colors.white.withAlpha(15),
        ),
      ],
    );
  }
}

class _ModeSegment extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ModeSegment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFF00B4D8), Color(0xFF00E5FF)],
                  )
                : null,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: const Color(0xFF00E5FF).withAlpha(60),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: selected ? Colors.black : Colors.white38),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: selected ? Colors.black : Colors.white38,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
