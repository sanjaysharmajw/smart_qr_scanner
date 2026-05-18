import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_qr_scanner/smart_qr_scanner.dart';

class HistoryScreen extends StatefulWidget {
  final List<SmartScanResult> items;
  const HistoryScreen({super.key, required this.items});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final all = widget.items;
    final items = _query.isEmpty
        ? all
        : all
            .where((r) =>
                r.rawValue.toLowerCase().contains(_query.toLowerCase()) ||
                r.typeName.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, all.length),
            if (all.isNotEmpty) _buildSearchBar(),
            Expanded(
              child: items.isEmpty
                  ? _buildEmpty(all.isEmpty)
                  : _buildList(items),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Scan History',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4)),
                if (count > 0)
                  Text('$count scans',
                      style: TextStyle(
                          color: Colors.white.withAlpha(100), fontSize: 13)),
              ],
            ),
          ),
          if (count > 0) ...[
            GestureDetector(
              onTap: () => HistoryExporter.exportCsv(widget.items),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF00E5FF).withAlpha(50), width: 1),
                ),
                child: const Icon(Icons.download_rounded,
                    color: Color(0xFF00E5FF), size: 20),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _confirmClear(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFFF6B6B).withAlpha(50), width: 1),
                ),
                child: const Icon(Icons.delete_sweep_rounded,
                    color: Color(0xFFFF6B6B), size: 20),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF16161F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(15), width: 1),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(Icons.search_rounded,
                  color: Colors.white.withAlpha(100), size: 20),
            ),
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search scans…',
                  hintStyle: TextStyle(
                      color: Colors.white.withAlpha(80), fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            if (_query.isNotEmpty)
              GestureDetector(
                onTap: () => setState(() => _query = ''),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(Icons.close_rounded,
                      color: Colors.white.withAlpha(100), size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool noScans) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                noScans ? Icons.history_rounded : Icons.search_off_rounded,
                size: 38,
                color: Colors.white.withAlpha(60),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              noScans ? 'No scans yet' : 'No results found',
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              noScans
                  ? 'Your scan history will appear here'
                  : 'Try a different search term',
              style:
                  TextStyle(color: Colors.white.withAlpha(80), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildList(List<SmartScanResult> items) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _HistoryTile(
            result: items[i],
            onDelete: () => setState(() => widget.items.remove(items[i])),
          ),
        ),
      );

  void _confirmClear(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        decoration: BoxDecoration(
          color: const Color(0xFF16161F),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withAlpha(15), width: 1),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_rounded,
                  color: Color(0xFFFF6B6B), size: 28),
            ),
            const SizedBox(height: 16),
            const Text('Clear All History',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'All scan records will be permanently deleted.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withAlpha(120), fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withAlpha(20), width: 1),
                      ),
                      child: const Center(
                        child: Text('Cancel',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => widget.items.clear());
                      Navigator.pop(context);
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B6B).withAlpha(80),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('Clear All',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
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
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              const Color(0xFFFF6B6B).withAlpha(60),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_rounded, color: Color(0xFFFF6B6B), size: 24),
            SizedBox(height: 4),
            Text('Delete',
                style: TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF16161F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(10), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF00E5FF).withAlpha(40),
                      const Color(0xFF7B2FFF).withAlpha(20),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF00E5FF).withAlpha(40), width: 1),
                ),
                child: const Icon(Icons.qr_code_2_rounded,
                    color: Color(0xFF00E5FF), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.rawValue.length > 48
                          ? '${result.rawValue.substring(0, 48)}…'
                          : result.rawValue,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _Chip(result.formatName),
                        const SizedBox(width: 6),
                        _Chip(result.typeName),
                        const Spacer(),
                        Text(
                          _timeAgo(result.timestamp),
                          style: TextStyle(
                              color: Colors.white.withAlpha(80), fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              FavoriteButton.forValue(result.rawValue, activeColor: Colors.amber),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: result.rawValue));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(children: [
                        Icon(Icons.check_circle_rounded,
                            color: Color(0xFF00E676), size: 18),
                        SizedBox(width: 10),
                        Text('Copied'),
                      ]),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.copy_rounded,
                      color: Colors.white.withAlpha(100), size: 17),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withAlpha(15), width: 1),
      ),
      child: Text(label,
          style:
              TextStyle(color: Colors.white.withAlpha(150), fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
