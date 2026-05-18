# smart_qr_scanner

[![pub version](https://img.shields.io/pub/v/smart_qr_scanner.svg)](https://pub.dev/packages/smart_qr_scanner) [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE) [![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios-green.svg)]()

A **production-ready** Flutter package for real-time QR code and barcode scanning powered by **Google ML Kit**. Drop in one widget, get a full-featured scanner with a modern animated UI, gallery scan, smooth camera switching, haptic feedback, scan history, and a clean developer API.

---

## Features

- **Real-time scanning** — high-FPS camera stream with ML Kit processing
- **Gallery scan** — pick any image from the device gallery and extract barcodes
- **13 barcode formats** — QR Code, Aztec, Codabar, Code 39/93/128, Data Matrix, EAN-8/13, ITF, PDF417, UPC-A/E
- **Smooth camera switch** — front/back toggle with fade-in, no preview crash
- **Modern loader** — glowing frame, sweep line, pulsing icon, animated dots
- **Animated scan line** — neon sweep with glow effect
- **Scan success animation** — elastic check-mark ring
- **Glassmorphism controls** — flash, flip, gallery buttons with blur backdrop
- **3 built-in themes** — Neon Cyan, Light, Minimal White + fully custom
- **Theme picker** — white bottom sheet with animated selection rows
- **Granular UI control** — show/hide flash, gallery, flip, and menu buttons individually
- **GlobalKey API** — expose `showThemePicker()` from any external button (e.g. AppBar)
- **Duplicate prevention** — configurable time-window deduplication
- **Scan history** — in-memory log with configurable capacity
- **Stream & Future APIs** — `onScan` callback and `scanOnce()` Future
- **Lifecycle aware** — auto-pause on background, resume on foreground
- **Timeout handling** — configurable scan deadline with callback
- **Single & continuous modes** — stop after first hit or keep scanning
- **Permission handling** — built-in request flow with settings deep-link
- **Haptic + audio feedback** — vibration and beep on each scan
- **Frame throttling** — configurable skip count to save CPU/battery

---

## Supported Formats

| Format      | Constant                   |
|-------------|----------------------------|
| QR Code     | `BarcodeFormat.qrCode`     |
| Aztec       | `BarcodeFormat.aztec`      |
| Codabar     | `BarcodeFormat.codabar`    |
| Code 39     | `BarcodeFormat.code39`     |
| Code 93     | `BarcodeFormat.code93`     |
| Code 128    | `BarcodeFormat.code128`    |
| Data Matrix | `BarcodeFormat.dataMatrix` |
| EAN-8       | `BarcodeFormat.ean8`       |
| EAN-13      | `BarcodeFormat.ean13`      |
| ITF         | `BarcodeFormat.itf`        |
| PDF417      | `BarcodeFormat.pdf417`     |
| UPC-A       | `BarcodeFormat.upca`       |
| UPC-E       | `BarcodeFormat.upce`       |

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

## Platform Setup

### Android

**`android/app/build.gradle`**
```gradle
android {
    defaultConfig {
        minSdkVersion 21   // ML Kit requires 21+
    }
}
```

**`android/app/src/main/AndroidManifest.xml`**
```xml
<uses-permission android:name="android.permission.CAMERA" />

<!-- inside <application> -->
<meta-data
    android:name="com.google.mlkit.vision.DEPENDENCIES"
    android:value="barcode_ui" />
```

### iOS

**`ios/Runner/Info.plist`**
```xml
<!-- Camera access (required) -->
<key>NSCameraUsageDescription</key>
<string>Camera access is required to scan QR codes and barcodes.</string>

<!-- Photo library access (required for gallery scan) -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Required to pick images from your gallery for QR code scanning.</string>
```

**`ios/Podfile`**
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
      config: const ScannerConfig(
        scanMode: ScanMode.single,
        enableVibration: true,
        enableSound: true,
      ),
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
        theme: ScannerTheme.light,
        hintText: 'Point at a QR code or barcode',
      );
}
```

### Future-based single scan

```dart
final result = await _controller.scanOnce();
print(result.rawValue);
```

### Gallery scan

```dart
// Opens the device photo picker, scans the selected image,
// and fires onScan (or onError if no code is found).
await _controller.scanFromGallery();
```

---

## Configuration

```dart
SmartQrScannerController(
  config: ScannerConfig(
    // Scan behaviour
    scanMode: ScanMode.single,           // or ScanMode.continuous
    cameraFacing: CameraFacing.back,     // or CameraFacing.front

    // Barcode formats (empty list = all 13 formats)
    formats: [BarcodeFormat.qrCode, BarcodeFormat.ean13],

    // Scan area (fraction of screen width/height)
    scanAreaWidthFactor: 0.75,
    scanAreaHeightFactor: 0.35,

    // Camera
    enableFlash: false,
    enableAutoFocus: true,

    // Feedback
    enableVibration: true,
    enableSound: true,

    // Duplicate prevention
    preventDuplicates: true,
    duplicatePreventionWindow: Duration(seconds: 2),

    // Performance
    framesToSkip: 0,           // 0 = every frame; 2 = every 3rd frame

    // Timeout (null = no timeout)
    scanTimeout: Duration(seconds: 30),

    // History
    enableScanHistory: true,
    maxHistoryItems: 50,

    // Analytics
    onAnalyticsEvent: (value, format) => myAnalytics.track(value, format),
  ),
);
```

---

## Controller API

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

// Gallery
await controller.scanFromGallery();

// State
controller.isInitialized    // bool
controller.isPaused         // bool
controller.isFlashOn        // bool
controller.isSwitching      // bool — true while swapping cameras
controller.permissionStatus // CameraPermissionStatus
controller.history          // List<SmartScanResult>
controller.errorMessage     // String?

// Callbacks
controller.onScan    = (SmartScanResult result) { ... };
controller.onRawScan = (List<SmartScanResult> all) { ... };
controller.onTimeout = () { ... };
controller.onError   = (String message) { ... };

// Streams
controller.scanEvents;     // Stream<SmartScanResult> — deduplicated
controller.rawScanEvents;  // Stream<List<SmartScanResult>> — every ML Kit batch

// Future API
final result = await controller.scanOnce();

// History
controller.clearHistory();
```

---

## Widget Parameters

```dart
SmartScannerWidget(
  controller: controller,

  // Theme (see Themes section below)
  theme: ScannerTheme.light,

  // Hint text shown below the scan area
  hintText: 'Align code within the frame',

  // Show/hide entire bottom control bar
  showControls: true,

  // Show/hide hint text
  showHint: true,

  // Show/hide individual bottom buttons
  showFlash: true,    // flash torch toggle
  showGallery: true,  // gallery image picker
  showFlip: true,     // front/back camera switch

  // Show/hide the built-in 3-dots theme picker button.
  // Set to false when you provide your own button via GlobalKey (see below).
  showMenu: true,

  // Called when user picks a theme from the bottom sheet
  onThemeChanged: (ScannerTheme t) => setState(() => _theme = t),

  // Override the default loading / error screens
  loadingWidget: MyLoadingScreen(),
  errorWidget:   MyErrorScreen(),
);
```

---

## Themes

### Built-in presets

```dart
ScannerTheme.neon     // Cyan glow, dark overlay (default)
ScannerTheme.light    // White corners, sky-blue scan line, soft overlay
ScannerTheme.minimal  // Pure white corners, minimal overlay
```

### Custom theme

```dart
ScannerTheme(
  overlayColor:              Color(0xAA000000), // dimmed area outside scan box
  borderColor:               Color(0xFF00E5FF), // corner bracket colour
  borderRadius:              16.0,
  borderStrokeWidth:         3.5,
  cornerLength:              28.0,
  scanLineColor:             Color(0xFF00E5FF),
  scanLineHeight:            2.5,
  scanLineAnimationDuration: Duration(milliseconds: 1800),
  glassTintColor:            Color(0x22FFFFFF),
  glassBlurSigma:            12.0,
  buttonColor:               Color(0x44FFFFFF),
  buttonIconColor:           Colors.white,
  successColor:              Color(0xFF00E676),
  hintTextStyle:             TextStyle(color: Colors.white, fontSize: 14),
)

// Or copy an existing preset and override only what you need:
ScannerTheme.neon.copyWith(borderColor: Colors.orange)
```

### Theme picker in a custom AppBar

Use `GlobalKey<SmartScannerWidgetState>` to call `showThemePicker()` from any
button — this guarantees the button is pixel-aligned with other AppBar widgets:

```dart
final _scannerKey = GlobalKey<SmartScannerWidgetState>();

// In your AppBar:
AppBar(
  actions: [
    IconButton(
      icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
      onPressed: () => _scannerKey.currentState?.showThemePicker(),
    ),
  ],
)

// Pass the key and disable the built-in menu button:
SmartScannerWidget(
  key: _scannerKey,
  controller: _controller,
  showMenu: false,           // hide internal button — AppBar handles it
  onThemeChanged: (t) => setState(() => _theme = t),
  // ...
)
```

---

## Scan Result

```dart
SmartScanResult {
  String   rawValue;       // Raw barcode string
  String?  displayValue;   // Human-friendly value (formatted URL, phone, etc.)
  BarcodeFormat format;    // e.g. BarcodeFormat.qrCode
  BarcodeType   type;      // e.g. BarcodeType.url
  DateTime      timestamp;
  ScanResultType resultType; // success | duplicate | error | timeout
  Rect?          boundingBox;
  List<Offset>?  cornerPoints;
  double?        confidence;     // 0.0 – 1.0
  Map<String, dynamic> metadata; // structured data: email, phone, url, wifi …

  // Helpers
  String formatName; // 'QR Code', 'EAN-13', …
  String typeName;   // 'URL', 'Email', …
  bool   isSuccess;
}
```
---

## Performance Tips

| Goal | Config |
|------|--------|
| Reduce CPU on slow devices | `framesToSkip: 2` |
| Faster cold start, lighter memory | `enableScanHistory: false` |
| Only need QR codes | `formats: [BarcodeFormat.qrCode]` |
| Prevent re-scan noise | `duplicatePreventionWindow: Duration(seconds: 3)` |
| Stop after first scan | `scanMode: ScanMode.single` |

---

## Troubleshooting

**Camera permission denied on iOS**  
Add `NSCameraUsageDescription` to `ios/Runner/Info.plist`.

**Gallery picker crashes on iOS**  
Add `NSPhotoLibraryUsageDescription` to `ios/Runner/Info.plist`.

**ML Kit models not downloading on Android**  
Add `<meta-data android:name="com.google.mlkit.vision.DEPENDENCIES" android:value="barcode_ui"/>` inside `<application>` in `AndroidManifest.xml`.

**Black camera preview**  
Call `controller.initialize()` before mounting the widget, and `controller.dispose()` inside your widget's `dispose()` method.

**`buildPreview() on disposed CameraController` crash**  
This is handled automatically by the package via the `isSwitching` flag, which swaps the preview for a black placeholder before the old controller is disposed.

**Slow detection**  
Increase `framesToSkip` or restrict `formats` to only what you need.

**No result from gallery image**  
The image must contain a clear, unobstructed barcode. Blurry, rotated, or very small codes may not be detected. `onError` is called with a descriptive message if nothing is found.

## License

```
MIT License — Copyright (c) 2024
```
