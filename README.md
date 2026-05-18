# smart_qr_scanner

[![pub version](https://img.shields.io/pub/v/smart_qr_scanner.svg)](https://pub.dev/packages/smart_qr_scanner)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios-green.svg)]()

A **production-ready** Flutter package for real-time QR code and barcode scanning powered by **Google ML Kit**. Features a beautiful modern UI with neon animations, glassmorphism overlays, haptic feedback, scan history, and a clean developer API.

---

## Features

- **Real-time scanning** — high-FPS camera stream with ML Kit processing
- **13 barcode formats** — QR Code, Aztec, Codabar, Code 39/93/128, Data Matrix, EAN-8/13, ITF, PDF417, UPC-A/E
- **Multiple codes at once** — detects all codes in a single frame
- **Animated scan line** — neon sweep animation with glow effect
- **Bounding boxes** — real-time corner detection with animated overlays
- **Scan success animation** — elastic check-mark ring
- **Glassmorphism controls** — flash toggle and camera flip with blur backdrop
- **Duplicate prevention** — configurable time-window deduplication
- **Scan history** — in-memory log with configurable capacity
- **Stream & Future APIs** — `onScan` callback and `scanOnce()` Future
- **Lifecycle aware** — auto-pause on background, resume on foreground
- **Timeout handling** — configurable scan deadline with callback
- **Single & continuous modes** — stop after first hit or keep scanning
- **Permission handling** — built-in request flow with settings deep-link
- **Haptic + audio feedback** — vibration and beep on each scan
- **3 built-in themes** — Neon Cyan, Indigo Light, Minimal White + full custom
- **Dark mode native** — all UI designed for dark backgrounds
- **Frame throttling** — configurable skip count to save CPU/battery
- **Low-light hint** — camera exposure tuning flag
- **Accessibility** — semantic labels on all controls

---

## Supported Formats

| Format       | Constant                    |
|--------------|-----------------------------|
| QR Code      | `BarcodeFormat.qrCode`      |
| Aztec        | `BarcodeFormat.aztec`       |
| Codabar      | `BarcodeFormat.codabar`     |
| Code 39      | `BarcodeFormat.code39`      |
| Code 93      | `BarcodeFormat.code93`      |
| Code 128     | `BarcodeFormat.code128`     |
| Data Matrix  | `BarcodeFormat.dataMatrix`  |
| EAN-8        | `BarcodeFormat.ean8`        |
| EAN-13       | `BarcodeFormat.ean13`       |
| ITF          | `BarcodeFormat.itf`         |
| PDF417       | `BarcodeFormat.pdf417`      |
| UPC-A        | `BarcodeFormat.upca`        |
| UPC-E        | `BarcodeFormat.upce`        |

---

## Installation

```yaml
dependencies:
  smart_qr_scanner: ^1.0.0
```

```bash
flutter pub get
```

---

## Android Setup

### `android/app/build.gradle`
```gradle
android {
    defaultConfig {
        minSdkVersion 21   // ML Kit requires 21+
    }
}
```

### `android/app/src/main/AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.CAMERA" />

<!-- inside <application> -->
<meta-data
    android:name="com.google.mlkit.vision.DEPENDENCIES"
    android:value="barcode_ui" />
```

---

## iOS Setup

### `ios/Runner/Info.plist`
```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required to scan QR codes and barcodes.</string>
```

### `ios/Podfile`
```ruby
platform :ios, '14.0'   # ML Kit requires iOS 14+
```

---

## Quick Start

### Drop-in widget (simplest)

```dart
import 'package:smart_qr_scanner/smart_qr_scanner.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});
  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  late final SmartQrScannerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SmartQrScannerController(
      config: const ScannerConfig(),
    );
    _controller.onScan = (result) {
      print('Scanned: ${result.rawValue} (${result.formatName})');
    };
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SmartScannerWidget(
        controller: _controller,
        theme: ScannerTheme.neon,
        hintText: 'Point at a QR code',
      );
}
```

### Future-based single scan

```dart
final result = await _controller.scanOnce();
print(result.rawValue);
```

---

## Configuration

```dart
SmartQrScannerController(
  config: ScannerConfig(
    // Scan mode
    scanMode: ScanMode.single,          // or ScanMode.continuous
    cameraFacing: CameraFacing.back,    // or CameraFacing.front

    // Barcode formats (empty = all 13 formats)
    formats: [BarcodeFormat.qrCode, BarcodeFormat.ean13],

    // Camera
    enableFlash: false,
    enableAutoFocus: true,
    enableAutoZoom: false,

    // Feedback
    enableVibration: true,
    enableSound: true,

    // Detection
    enableBoundingBox: true,
    preventDuplicates: true,
    duplicatePreventionWindow: Duration(seconds: 2),

    // Performance
    framesToSkip: 0,           // 0 = process every frame
    enableLowLightOptimization: true,

    // Timeout (null = no timeout)
    scanTimeout: Duration(seconds: 30),

    // History
    enableScanHistory: true,
    maxHistoryItems: 50,

    // Analytics hook
    onAnalyticsEvent: (value, format) => myAnalytics.track(value, format),
  ),
);
```

---

## Scanner Controller API

```dart
// Lifecycle
await controller.initialize();
await controller.dispose();

// Playback
controller.pause();
controller.resume();

// Camera
await controller.toggleFlash();
await controller.switchCamera();

// State
controller.isInitialized   // bool
controller.isPaused        // bool
controller.isFlashOn       // bool
controller.permissionStatus // CameraPermissionStatus
controller.history          // List<SmartScanResult>

// Callbacks
controller.onScan    = (SmartScanResult result) { ... };
controller.onRawScan = (List<SmartScanResult> all) { ... };
controller.onTimeout = () { ... };
controller.onError   = (String message) { ... };

// Future API
final result = await controller.scanOnce();

// History
controller.clearHistory();
```

---

## Widget Customization

```dart
SmartScannerWidget(
  controller: controller,

  // Theme
  theme: ScannerTheme(
    overlayColor:   Color(0xAA000000),
    borderColor:    Color(0xFF00E5FF),
    borderRadius:   16.0,
    cornerLength:   28.0,
    scanLineColor:  Color(0xFF00E5FF),
    successColor:   Color(0xFF00E676),
    glassTintColor: Color(0x22FFFFFF),
    glassBlurSigma: 12.0,
    buttonColor:    Color(0x44FFFFFF),
    hintTextStyle:  TextStyle(color: Colors.white, fontSize: 14),
    scanLineAnimationDuration: Duration(milliseconds: 1800),
  ),

  // Content
  hintText: 'Align code within the frame',
  showControls: true,   // flash + flip buttons
  showHint: true,       // hint pill below scan area

  // Custom widgets for edge cases
  loadingWidget: MyLoadingScreen(),
  errorWidget:   MyErrorScreen(),
);
```

### Built-in themes

```dart
ScannerTheme.neon     // Cyan glow (default)
ScannerTheme.light    // Indigo accents
ScannerTheme.minimal  // Pure white
```

---

## Scan Result

```dart
SmartScanResult {
  String rawValue;          // Raw barcode content
  String? displayValue;     // Human-friendly value (e.g. formatted URL)
  BarcodeFormat format;     // e.g. BarcodeFormat.qrCode
  BarcodeType type;         // e.g. BarcodeType.url
  DateTime timestamp;
  ScanResultType resultType; // success | duplicate | error | timeout
  Rect? boundingBox;
  List<Offset>? cornerPoints;
  double? confidence;        // 0.0–1.0
  Map<String, dynamic> metadata; // email, phone, url, wifi, etc.

  // Helpers
  String formatName;   // 'QR Code', 'EAN-13', ...
  String typeName;     // 'URL', 'Email', ...
  bool isSuccess;
}
```

---

## Architecture

```
lib/
├── smart_qr_scanner.dart          # Public API barrel export
└── src/
    ├── models/
    │   ├── scan_result.dart        # SmartScanResult
    │   ├── scanner_config.dart     # ScannerConfig, ScanMode, CameraFacing
    │   └── scanner_theme.dart      # ScannerTheme
    ├── controllers/
    │   └── scanner_controller.dart # SmartQrScannerController (ChangeNotifier)
    ├── engine/
    │   └── scanner_engine.dart     # Camera + ML Kit integration
    ├── services/
    │   ├── permission_service.dart # Camera permission wrapper
    │   ├── feedback_service.dart   # Vibration + audio
    │   └── history_service.dart    # In-memory scan log
    ├── ui/
    │   ├── smart_scanner_widget.dart       # Drop-in scanner widget
    │   ├── painters/
    │   │   ├── scanner_overlay_painter.dart # Mask + corners + scan line
    │   │   └── bounding_box_painter.dart    # Detected code outlines
    │   └── components/
    │       ├── scan_controls.dart           # Flash / flip buttons
    │       ├── scan_hint_widget.dart        # Glassmorphism hint pill
    │       └── scan_success_animation.dart  # Check-mark ring
    └── utils/
        ├── image_utils.dart    # CameraImage → InputImage
        ├── barcode_utils.dart  # Validation & format helpers
        └── throttle_utils.dart # FrameThrottle, Debouncer
```

---

## Performance Tips

| Tip | Config |
|-----|--------|
| Reduce CPU on slow devices | `framesToSkip: 2` |
| Faster detection, less history | `enableScanHistory: false` |
| Only need QR codes | `formats: [BarcodeFormat.qrCode]` |
| Prevent re-scan noise | `duplicatePreventionWindow: Duration(seconds: 3)` |
| Stop after first scan | `scanMode: ScanMode.single` |

---

## Troubleshooting

**Camera permission denied on iOS**  
Ensure `NSCameraUsageDescription` is in `Info.plist`.

**ML Kit models not downloading on Android**  
Add `<meta-data android:name="com.google.mlkit.vision.DEPENDENCIES" android:value="barcode_ui"/>` to `AndroidManifest.xml`.

**Black camera preview**  
Call `controller.initialize()` before mounting the widget and `controller.dispose()` in `dispose()`.

**Slow detection**  
Increase `framesToSkip` or restrict `formats` to only the formats you need.

**Bounding boxes misaligned**  
The widget automatically scales ML Kit coordinates to widget space. If your app forces a custom aspect ratio, override `_scaledResults` in a custom subclass.

---

## Example App

The `/example` folder contains a full demo app with:

- **Home** — feature overview and quick-action navigation
- **Scanner** — live scanning with theme switcher
- **Result** — rich result detail with copy and re-scan
- **History** — dismissible list with swipe-to-delete
- **Settings** — all `ScannerConfig` options with live preview
- **Themes** — visual theme picker with miniature preview painter

---

## License

```
MIT License — Copyright (c) 2024
```
