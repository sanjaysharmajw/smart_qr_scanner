import 'package:flutter/material.dart';

/// Visual theme for the scanner overlay and controls.
@immutable
class ScannerTheme {
  /// Color of the dark overlay outside the scan area.
  final Color overlayColor;

  /// Color of the scan-area border corners.
  final Color borderColor;

  /// Radius of the corner brackets.
  final double borderRadius;

  /// Stroke width of the corner brackets.
  final double borderStrokeWidth;

  /// Length of each corner bracket leg.
  final double cornerLength;

  /// Color of the animated scan line.
  final Color scanLineColor;

  /// Height of the scan line gradient.
  final double scanLineHeight;

  /// Duration of one complete scan-line sweep.
  final Duration scanLineAnimationDuration;

  /// Tint of the glassmorphism background behind the hint text.
  final Color glassTintColor;

  /// Blur sigma for the glassmorphism effect.
  final double glassBlurSigma;

  /// Text style applied to the hint label.
  final TextStyle hintTextStyle;

  /// Color used for action buttons (flash, flip camera).
  final Color buttonColor;

  /// Icon color inside action buttons.
  final Color buttonIconColor;

  /// Background color for the success animation ring.
  final Color successColor;

  const ScannerTheme({
    this.overlayColor = const Color(0xAA000000),
    this.borderColor = const Color(0xFF00E5FF),
    this.borderRadius = 16.0,
    this.borderStrokeWidth = 3.5,
    this.cornerLength = 28.0,
    this.scanLineColor = const Color(0xFF00E5FF),
    this.scanLineHeight = 2.5,
    this.scanLineAnimationDuration = const Duration(milliseconds: 1800),
    this.glassTintColor = const Color(0x22FFFFFF),
    this.glassBlurSigma = 12.0,
    this.hintTextStyle = const TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.4,
    ),
    this.buttonColor = const Color(0x44FFFFFF),
    this.buttonIconColor = Colors.white,
    this.successColor = const Color(0xFF00E676),
  });

  /// A dark neon-cyan theme (default).
  static const ScannerTheme neon = ScannerTheme();

  /// A clean light-mode theme — white corners, sky-blue scan line, soft overlay.
  static const ScannerTheme light = ScannerTheme(
    overlayColor: Color(0x55000000),
    borderColor: Colors.white,
    borderRadius: 20.0,
    borderStrokeWidth: 3.0,
    cornerLength: 30.0,
    scanLineColor: Color(0xFF80DEEA),
    scanLineHeight: 2.0,
    scanLineAnimationDuration: Duration(milliseconds: 2200),
    glassTintColor: Color(0x44FFFFFF),
    glassBlurSigma: 16.0,
    successColor: Color(0xFF69F0AE),
    hintTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.3,
    ),
  );

  /// A pure-white/minimal theme for branded apps.
  static const ScannerTheme minimal = ScannerTheme(
    overlayColor: Color(0x99000000),
    borderColor: Colors.white,
    scanLineColor: Colors.white,
    successColor: Colors.white,
    glassBlurSigma: 8.0,
  );

  ScannerTheme copyWith({
    Color? overlayColor,
    Color? borderColor,
    double? borderRadius,
    double? borderStrokeWidth,
    double? cornerLength,
    Color? scanLineColor,
    double? scanLineHeight,
    Duration? scanLineAnimationDuration,
    Color? glassTintColor,
    double? glassBlurSigma,
    TextStyle? hintTextStyle,
    Color? buttonColor,
    Color? buttonIconColor,
    Color? successColor,
  }) =>
      ScannerTheme(
        overlayColor: overlayColor ?? this.overlayColor,
        borderColor: borderColor ?? this.borderColor,
        borderRadius: borderRadius ?? this.borderRadius,
        borderStrokeWidth: borderStrokeWidth ?? this.borderStrokeWidth,
        cornerLength: cornerLength ?? this.cornerLength,
        scanLineColor: scanLineColor ?? this.scanLineColor,
        scanLineHeight: scanLineHeight ?? this.scanLineHeight,
        scanLineAnimationDuration:
            scanLineAnimationDuration ?? this.scanLineAnimationDuration,
        glassTintColor: glassTintColor ?? this.glassTintColor,
        glassBlurSigma: glassBlurSigma ?? this.glassBlurSigma,
        hintTextStyle: hintTextStyle ?? this.hintTextStyle,
        buttonColor: buttonColor ?? this.buttonColor,
        buttonIconColor: buttonIconColor ?? this.buttonIconColor,
        successColor: successColor ?? this.successColor,
      );
}
