import 'package:flutter/material.dart';
import 'package:smart_qr_scanner/smart_qr_scanner.dart';

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  static const _accent = Color(0xFF7C4DFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 20, offset: const Offset(0, 4))],
                      ),
                      child: const QrGeneratorWidget(
                        accentColor: _accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withAlpha(15)),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8)],
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 20, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('QR Generator', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87, letterSpacing: -0.4)),
                Text('Create QR codes instantly', style: TextStyle(fontSize: 13, color: Colors.black45)),
              ],
            ),
          ),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _accent.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.qr_code_2_rounded, color: _accent, size: 22),
          ),
        ],
      ),
    );
  }
}

