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
    this.overlayColor = const Color(0xBB000000),
    this.borderColor = const Color(0xFF7C4DFF),
    this.borderRadius = 18.0,
    this.borderStrokeWidth = 4.0,
    this.cornerLength = 30.0,
    this.scanLineColor = const Color(0xFF18FFFF),
    this.scanLineHeight = 3.0,
    this.scanLineAnimationDuration = const Duration(milliseconds: 1500),
    this.glassTintColor = const Color(0x127C4DFF),
    this.glassBlurSigma = 18.0,
    this.hintTextStyle = const TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    this.buttonColor = const Color(0x44FFFFFF),
    this.buttonIconColor = Colors.white,
    this.successColor = const Color(0xFF69F0AE),
  });

  /// Cyber — deep violet brackets, electric cyan scan line, dark overlay.
  static const ScannerTheme neon = ScannerTheme();

  /// Aurora — warm gold brackets, amber scan line, soft overlay.
  static const ScannerTheme light = ScannerTheme(
    overlayColor: Color(0x55000000),
    borderColor: Color(0xFFFFD740),
    borderRadius: 22.0,
    borderStrokeWidth: 3.0,
    cornerLength: 34.0,
    scanLineColor: Color(0xFFFFAB40),
    scanLineHeight: 2.5,
    scanLineAnimationDuration: Duration(milliseconds: 2000),
    glassTintColor: Color(0x18FFD740),
    glassBlurSigma: 20.0,
    hintTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.3,
    ),
  );

  /// Ghost — ultra-thin white brackets, heavy vignette, stealth aesthetic.
  static const ScannerTheme minimal = ScannerTheme(
    overlayColor: Color(0xCC000000),
    borderColor: Colors.white,
    borderRadius: 26.0,
    borderStrokeWidth: 2.0,
    cornerLength: 24.0,
    scanLineColor: Color(0xAAFFFFFF),
    scanLineHeight: 1.5,
    scanLineAnimationDuration: Duration(milliseconds: 2600),
    glassTintColor: Color(0x0AFFFFFF),
    glassBlurSigma: 14.0,
    successColor: Color(0xFFFFFFFF),
    hintTextStyle: TextStyle(
      color: Colors.white70,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.8,
    ),
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
