import 'dart:ui';
import 'package:flutter/material.dart';
import '../../controllers/scanner_controller.dart';
import '../../models/scanner_theme.dart';

/// Bottom control bar: [Flash?] · [Center pill] · [Gallery?] · [Flip?]
/// Each side button can be shown or hidden independently.
class ScanControls extends StatelessWidget {
  final SmartQrScannerController controller;
  final ScannerTheme theme;
  final bool showFlash;
  final bool showGallery;
  final bool showFlip;

  const ScanControls({
    super.key,
    required this.controller,
    required this.theme,
    this.showFlash = true,
    this.showGallery = true,
    this.showFlip = true,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottom),
      child: Row(
        children: [
          // Flash circle
          if (showFlash) ...[
            _CircleBtn(
              icon: controller.isFlashOn
                  ? Icons.flash_on_rounded
                  : Icons.flash_off_rounded,
              active: controller.isFlashOn,
              accent: const Color(0xFFFFD60A),
              onTap: controller.toggleFlash,
            ),
            const SizedBox(width: 12),
          ],
          // Center pill (expands to fill)
          Expanded(child: _CenterPill(controller: controller)),
          // Gallery circle
          if (showGallery) ...[
            const SizedBox(width: 12),
            _CircleBtn(
              icon: Icons.photo_library_rounded,
              active: false,
              accent: Colors.white70,
              onTap: controller.scanFromGallery,
            ),
          ],
          // Flip circle
          if (showFlip) ...[
            const SizedBox(width: 8),
            _CircleBtn(
              icon: Icons.flip_camera_ios_rounded,
              active: false,
              accent: Colors.white70,
              onTap: controller.switchCamera,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Center frosted pill ───────────────────────────────────────────────────────

class _CenterPill extends StatelessWidget {
  final SmartQrScannerController controller;
  const _CenterPill({required this.controller});

  @override
  Widget build(BuildContext context) {
    final paused = controller.isPaused;
    return GestureDetector(
      onTap: paused ? controller.resume : controller.pause,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 52,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(120),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.white.withAlpha(35)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  paused
                      ? Icons.play_circle_outline_rounded
                      : Icons.crop_free_rounded,
                  color: Colors.white,
                  size: 19,
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    paused ? 'Resume' : 'Auto Focus',
                    key: ValueKey(paused),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Small circle button ───────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  const _CircleBtn({
    required this.icon,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? accent.withAlpha(50)
                  : Colors.black.withAlpha(120),
              border: Border.all(
                color: active ? accent.withAlpha(180) : Colors.white.withAlpha(35),
              ),
              boxShadow: active
                  ? [BoxShadow(color: accent.withAlpha(120), blurRadius: 14)]
                  : [],
            ),
            child: Icon(
              icon,
              color: active ? accent : Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
