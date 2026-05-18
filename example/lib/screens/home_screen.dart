import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_qr_scanner/smart_qr_scanner.dart';
import 'scanner_screen.dart';
import 'result_screen.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
abstract final class _C {
  static const bg       = Color(0xFFF0F7FF);
  static const primary  = Color(0xFF00BCD4);
  static const dark     = Color(0xFF00838F);
  static const text     = Color(0xFF1A1A2E);
  static const mid      = Color(0xFF6B7280);
  static const light    = Color(0xFFB0B8C4);
  static const border   = Color(0xFFE8EFF8);
  static const error    = Color(0xFFFF5B5B);
  static const success  = Color(0xFF00C48C);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00BCD4), Color(0xFF006064)],
  );
}

// ── Root shell ────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  final _history = <SmartScanResult>[];

  void _addResult(SmartScanResult r) => setState(() => _history.insert(0, r));

  void _openScanner(BuildContext context, ScannerConfig config,
      {ScannerTheme theme = ScannerTheme.light}) {
    // Pre-create and start initializing the controller NOW, before the route
    // transition begins. Camera init (~500 ms) overlaps with the slide animation
    // so the preview is ready the moment the screen lands.
    final controller = SmartQrScannerController(config: config);
    controller.initialize();

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ScannerScreen(
          controller: controller,
          theme: theme,
          onResult: _addResult,
        ),
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        transitionsBuilder: (_, animation, __, child) {
          final slide = Tween(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
          final fade = Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: const Interval(0, 0.5)));
          return SlideTransition(position: slide, child: FadeTransition(opacity: fade, child: child));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: IndexedStack(
        index: _tab,
        children: [
          _ScanTab(
            onOpen: (cfg, {theme}) =>
                _openScanner(context, cfg, theme: theme ?? ScannerTheme.light),
            recent: _history.take(3).toList(),
            onViewHistory: () => setState(() => _tab = 1),

          ),
          _HistoryTab(history: _history),
          const _GenerateTab(),
          const _SettingsTab(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        current: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

// ── Bottom navigation ─────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.current, required this.onTap});

  static const _items = [
    (Icons.qr_code_scanner_rounded, Icons.qr_code_scanner_rounded, 'Scan'),
    (Icons.history_rounded, Icons.history_rounded, 'History'),
    (Icons.qr_code_2_rounded, Icons.qr_code_2_rounded, 'Generate'),
    (Icons.settings_rounded, Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: Colors.transparent,
      child: Container(
        margin: EdgeInsets.fromLTRB(20, 0, 20, (bottom > 0 ? bottom : 16)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: _C.primary.withAlpha(30),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_items.length, (i) {
            final selected = i == current;
            final item = _items[i];
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  decoration: selected
                      ? BoxDecoration(
                          gradient: _C.gradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: _C.primary.withAlpha(70),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        )
                      : const BoxDecoration(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.$1,
                        size: 22,
                        color: selected ? Colors.white : _C.light,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.$3,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : _C.light,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── Scan Tab ──────────────────────────────────────────────────────────────────

typedef _OpenFn = void Function(ScannerConfig config, {ScannerTheme? theme});

class _ScanTab extends StatelessWidget {
  final _OpenFn onOpen;
  final List<SmartScanResult> recent;
  final VoidCallback onViewHistory;

  const _ScanTab({
    required this.onOpen,
    required this.recent,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildTopBar()),
        SliverToBoxAdapter(child: _buildHeroCard()),
        SliverToBoxAdapter(child: _buildSectionLabel('Quick Modes')),
        SliverToBoxAdapter(child: _buildFeatureGrid()),
        SliverToBoxAdapter(child: _buildSectionLabel('Scanner Themes')),
        SliverToBoxAdapter(child: _buildThemeRow()),
        if (recent.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _buildSectionLabel('Recent Scans', action: 'View All', onAction: onViewHistory),
          ),
          SliverToBoxAdapter(child: _buildRecent()),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: _C.gradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _C.primary.withAlpha(80),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Smart QR Scanner',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _C.text,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                'Powered by ML Kit',
                style: TextStyle(
                  fontSize: 11,
                  color: _C.mid,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _C.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'v1.0',
              style: TextStyle(
                fontSize: 11,
                color: _C.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Builder(builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: GestureDetector(
          onTap: () => onOpen(const ScannerConfig(
            scanMode: ScanMode.single,
            enableVibration: true,
          )),
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: _C.gradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: _C.primary.withAlpha(80),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(15),
                    ),
                  ),
                ),
                Positioned(
                  right: 30,
                  bottom: -50,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.qr_code_scanner_rounded,
                            color: Colors.white, size: 28),
                      ),
                      const Spacer(),
                      const Text(
                        'Tap to Scan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'QR codes, barcodes & more',
                        style: TextStyle(
                          color: Colors.white.withAlpha(180),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 24,
                  bottom: 24,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withAlpha(50), width: 1),
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSectionLabel(String label, {String? action, VoidCallback? onAction}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _C.text,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Row(
                children: [
                  Text(
                    action,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _C.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: _C.primary),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid() {
    final items = [
      (Icons.all_inclusive_rounded, 'Continuous', const Color(0xFF7C3AED),
          const ScannerConfig(scanMode: ScanMode.continuous, enableVibration: true)),
      (Icons.flash_on_rounded, 'Flash', const Color(0xFFF59E0B),
          const ScannerConfig(scanMode: ScanMode.single, enableFlash: true, enableVibration: true)),
      (Icons.copy_all_rounded, 'No Dupes', const Color(0xFF10B981),
          const ScannerConfig(scanMode: ScanMode.continuous, preventDuplicates: true, duplicatePreventionWindow: Duration(seconds: 5), enableVibration: true)),
      (Icons.timer_rounded, '10s Limit', const Color(0xFFEF4444),
          const ScannerConfig(scanMode: ScanMode.single, scanTimeout: Duration(seconds: 10), enableVibration: true)),
      (Icons.camera_front_rounded, 'Front Cam', const Color(0xFF3B82F6),
          const ScannerConfig(scanMode: ScanMode.single, cameraFacing: CameraFacing.front, enableVibration: true)),
      (Icons.image_search_rounded, 'Gallery', const Color(0xFFEC4899),
          const ScannerConfig(scanMode: ScanMode.single, enableVibration: true)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
        children: items.map((item) => _FeatureCard(
          icon: item.$1,
          label: item.$2,
          color: item.$3,
          onTap: () => onOpen(item.$4),
        )).toList(),
      ),
    );
  }

  Widget _buildThemeRow() {
    final themes = [
      ('Neon', const Color(0xFF00E5FF), ScannerTheme.neon),
      ('Light', const Color(0xFFF59E0B), ScannerTheme.light),
      ('Minimal', const Color(0xFF8E8E93), ScannerTheme.minimal),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: themes.map((t) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: t.$1 == 'Minimal' ? 0 : 10),
              child: _ThemeChip(
                label: t.$1,
                color: t.$2,
                onTap: () => onOpen(
                  const ScannerConfig(
                    scanMode: ScanMode.single,
                    enableVibration: true,
                  ),
                  theme: t.$3,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: recent.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _RecentTile(result: r),
        )).toList(),
      ),
    );
  }
}

// ── Feature card ──────────────────────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _FeatureCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(18),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _C.text,
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

// ── Theme chip ────────────────────────────────────────────────────────────────

class _ThemeChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ThemeChip({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                gradient: RadialGradient(colors: [color, color.withAlpha(160)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withAlpha(120), blurRadius: 8)],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: _C.text,
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

// ── Recent scan tile ──────────────────────────────────────────────────────────

class _RecentTile extends StatelessWidget {
  final SmartScanResult result;
  const _RecentTile({required this.result});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(result: result)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_C.primary.withAlpha(40), _C.dark.withAlpha(30)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.qr_code_2_rounded, color: _C.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.rawValue.length > 42
                        ? '${result.rawValue.substring(0, 42)}…'
                        : result.rawValue,
                    style: const TextStyle(
                      color: _C.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _MiniChip(result.typeName),
                      const SizedBox(width: 6),
                      Text(_ago(result.timestamp),
                          style: const TextStyle(fontSize: 11, color: _C.mid)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _C.light, size: 18),
          ],
        ),
      ),
    );
  }

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  const _MiniChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _C.primary.withAlpha(18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _C.primary,
        ),
      ),
    );
  }
}

// ── History Tab ───────────────────────────────────────────────────────────────

class _HistoryTab extends StatefulWidget {
  final List<SmartScanResult> history;
  const _HistoryTab({required this.history});

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final all = widget.history;
    final items = _query.isEmpty
        ? all
        : all.where((r) =>
            r.rawValue.toLowerCase().contains(_query.toLowerCase()) ||
            r.typeName.toLowerCase().contains(_query.toLowerCase())).toList();

    return Column(
      children: [
        _buildHeader(all.length),
        if (all.isNotEmpty) _buildSearch(),
        Expanded(
          child: items.isEmpty
              ? _buildEmpty(all.isEmpty)
              : _buildList(items),
        ),
      ],
    );
  }

  Widget _buildHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scan History',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: _C.text,
                    letterSpacing: -0.6,
                  ),
                ),
                Text(
                  count == 0 ? 'No scans yet' : '$count scan${count != 1 ? 's' : ''} recorded',
                  style: const TextStyle(fontSize: 13, color: _C.mid),
                ),
              ],
            ),
          ),
          if (count > 0) ...[
            _IconBtn(
              icon: Icons.download_rounded,
              color: _C.primary,
              onTap: () => HistoryExporter.exportCsv(widget.history),
            ),
            const SizedBox(width: 8),
            _IconBtn(
              icon: Icons.delete_sweep_rounded,
              color: _C.error,
              onTap: () => _confirmClear(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 14, right: 10),
              child: Icon(Icons.search_rounded, color: _C.light, size: 20),
            ),
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(color: _C.text, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search scans…',
                  hintStyle: TextStyle(color: _C.light, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            if (_query.isNotEmpty)
              GestureDetector(
                onTap: () => setState(() => _query = ''),
                child: const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.close_rounded, color: _C.light, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool noScans) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: _C.primary.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              noScans ? Icons.history_rounded : Icons.search_off_rounded,
              size: 38,
              color: _C.primary.withAlpha(140),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            noScans ? 'No scans yet' : 'No results found',
            style: const TextStyle(
              color: _C.text,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            noScans ? 'Scan a QR code to see it here' : 'Try a different keyword',
            style: const TextStyle(color: _C.mid, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<SmartScanResult> items) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _HistoryTile(
          result: items[i],
          onDelete: () => setState(() => widget.history.remove(items[i])),
        ),
      ),
    );
  }

  void _confirmClear(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 32)],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _C.error.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_rounded, color: _C.error, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('Clear All History',
                style: TextStyle(color: _C.text, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('All scan records will be permanently deleted.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _C.mid, fontSize: 14, height: 1.5)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _OutlineBtn(
                    label: 'Cancel',
                    onTap: () => Navigator.pop(ctx),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FilledBtn(
                    label: 'Clear All',
                    color: _C.error,
                    onTap: () {
                      setState(() => widget.history.clear());
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final SmartScanResult result;
  final VoidCallback onDelete;
  const _HistoryTile({required this.result, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(result.rawValue + result.timestamp.toIso8601String()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: _C.error.withAlpha(20),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_rounded, color: _C.error, size: 22),
            SizedBox(height: 4),
            Text('Delete', style: TextStyle(color: _C.error, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ResultScreen(result: result)),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_C.primary.withAlpha(40), _C.dark.withAlpha(25)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.qr_code_2_rounded, color: _C.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.rawValue.length > 44
                          ? '${result.rawValue.substring(0, 44)}…'
                          : result.rawValue,
                      style: const TextStyle(
                        color: _C.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _MiniChip(result.typeName),
                        const SizedBox(width: 6),
                        _MiniChip(result.formatName),
                        const Spacer(),
                        Text(_ago(result.timestamp),
                            style: const TextStyle(color: _C.light, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FavoriteButton.forValue(result.rawValue, activeColor: const Color(0xFFF59E0B)),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: result.rawValue));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(children: [
                        Icon(Icons.check_circle_rounded, color: _C.success, size: 18),
                        SizedBox(width: 10),
                        Text('Copied'),
                      ]),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _C.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.copy_rounded, color: _C.mid, size: 17),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

// ── Generate Tab ──────────────────────────────────────────────────────────────

class _GenerateTab extends StatelessWidget {
  const _GenerateTab();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'QR Generator',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: _C.text,
                    letterSpacing: -0.6,
                  ),
                ),
                const Text(
                  'Create QR codes instantly',
                  style: TextStyle(fontSize: 13, color: _C.mid),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: _C.primary.withAlpha(20),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: const QrGeneratorWidget(
                    accentColor: _C.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Settings Tab ──────────────────────────────────────────────────────────────

class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  bool _vibration = true;
  bool _boundingBox = true;
  bool _preventDuplicates = true;
  ScanMode _scanMode = ScanMode.single;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 32),
      physics: const BouncingScrollPhysics(),
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: _C.text,
            letterSpacing: -0.6,
          ),
        ),
        const Text(
          'Customize your scan experience',
          style: TextStyle(fontSize: 13, color: _C.mid),
        ),
        const SizedBox(height: 28),

        _SettingCard(
          icon: Icons.radar_rounded,
          iconColor: _C.primary,
          title: 'Scan Mode',
          child: _ModeToggle(
            value: _scanMode,
            onChange: (v) => setState(() => _scanMode = v),
          ),
        ),
        const SizedBox(height: 14),

        _SettingCard(
          icon: Icons.notifications_active_rounded,
          iconColor: const Color(0xFFF59E0B),
          title: 'Feedback',
          child: Column(
            children: [
              _ToggleRow(
                icon: Icons.vibration_rounded,
                iconColor: const Color(0xFFF59E0B),
                label: 'Vibration',
                sub: 'Haptic on scan',
                value: _vibration,
                onChanged: (v) => setState(() => _vibration = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        _SettingCard(
          icon: Icons.center_focus_strong_rounded,
          iconColor: const Color(0xFF7C3AED),
          title: 'Detection',
          child: Column(
            children: [
              _ToggleRow(
                icon: Icons.crop_free_rounded,
                iconColor: const Color(0xFF7C3AED),
                label: 'Bounding Box',
                sub: 'Highlight detected code',
                value: _boundingBox,
                onChanged: (v) => setState(() => _boundingBox = v),
              ),
              _divider(),
              _ToggleRow(
                icon: Icons.block_rounded,
                iconColor: _C.error,
                label: 'Prevent Duplicates',
                sub: 'Skip repeated scans',
                value: _preventDuplicates,
                onChanged: (v) => setState(() => _preventDuplicates = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // About card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: _C.gradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _C.primary.withAlpha(60),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Smart QR Scanner',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                  Text('Version 1.0.0 · Powered by ML Kit',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(
    height: 1,
    color: _C.border,
    margin: const EdgeInsets.symmetric(vertical: 4),
  );
}

class _SettingCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;
  const _SettingCard({required this.icon, required this.iconColor, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 4),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: iconColor, size: 13),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.icon, required this.iconColor, required this.label,
    required this.sub, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: _C.text, fontSize: 14, fontWeight: FontWeight.w600)),
                Text(sub, style: const TextStyle(color: _C.mid, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _C.primary,
            activeTrackColor: _C.primary.withAlpha(80),
          ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final ScanMode value;
  final ValueChanged<ScanMode> onChange;
  const _ModeToggle({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.border,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _seg(ScanMode.single, Icons.touch_app_rounded, 'Single'),
          _seg(ScanMode.continuous, Icons.all_inclusive_rounded, 'Continuous'),
        ],
      ),
    );
  }

  Widget _seg(ScanMode mode, IconData icon, String label) {
    final sel = value == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChange(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: sel ? _C.gradient : null,
            borderRadius: BorderRadius.circular(9),
            boxShadow: sel
                ? [BoxShadow(color: _C.primary.withAlpha(60), blurRadius: 8, offset: const Offset(0, 3))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: sel ? Colors.white : _C.mid),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: sel ? Colors.white : _C.mid,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared micro-widgets ──────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withAlpha(40), width: 1),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: _C.border,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(color: _C.text, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _FilledBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _FilledBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withAlpha(80), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
