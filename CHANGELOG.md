## 1.0.0

### Initial Release

**Core Scanning**
- Real-time QR code and barcode scanning powered by Google ML Kit
- Supports 13 barcode formats: QR Code, Aztec, Codabar, Code 39/93/128, Data Matrix, EAN-8/13, ITF, PDF417, UPC-A/E
- Single-scan and continuous-scan modes (`ScanMode.single` / `ScanMode.continuous`)
- Configurable scan area with `scanAreaWidthFactor` and `scanAreaHeightFactor`
- Frame throttling (`framesToSkip`) to reduce CPU/battery usage
- Scan-area filtering — only barcodes whose centre falls inside the scan window are accepted

**Gallery Scanning**
- `scanFromGallery()` on `SmartQrScannerController` — pick any image from the device gallery and extract barcodes via ML Kit
- Fires `onScan` on success; fires `onError` if no valid code is found in the image
- Adds result to scan history and triggers haptic/audio feedback like a live scan
- Requires `NSPhotoLibraryUsageDescription` in iOS `Info.plist`

**Camera**
- Front/back camera switch via `switchCamera()` — fixed a bug where `config.cameraFacing` was immutable and the camera always re-initialised to the same direction; the engine now tracks `_currentFacing` separately
- Smooth camera switch: sets `isSwitching = true` and renders a black placeholder before disposing the old `CameraController`, preventing the `buildPreview() on disposed CameraController` crash
- Fade-in animation (`TweenAnimationBuilder`) when the new camera preview appears after switching
- Flash toggle via `toggleFlash()`; flash automatically disabled when using the front camera
- Auto-focus mode configurable via `ScannerConfig.enableAutoFocus`

**Controller API**
- `SmartQrScannerController` extends `ChangeNotifier` — use with `ListenableBuilder` or `addListener`
- `scanEvents` — broadcast `Stream<SmartScanResult>` for every new non-duplicate result
- `rawScanEvents` — broadcast `Stream<List<SmartScanResult>>` for every raw ML Kit batch
- `onScan`, `onRawScan`, `onTimeout`, `onError` — simple callback API
- `scanOnce()` — `Future<SmartScanResult>` for single-scan flow without callbacks
- `pause()` / `resume()` — stop/start frame processing without closing the camera
- `clearHistory()` — reset the in-memory scan log
- `isSwitching` getter — true while the camera is being swapped (used by the widget to show a black placeholder)

**UI — SmartScannerWidget**
- `showControls` — show/hide the bottom control bar
- `showHint` — show/hide the hint text below the scan area
- `showFlash` — show/hide the flash toggle button individually
- `showGallery` — show/hide the gallery picker button individually
- `showFlip` — show/hide the camera flip button individually
- `showMenu` — show/hide the built-in 3-dots theme picker button (set `false` when providing your own AppBar actions button)
- `onThemeChanged` — callback fired when the user picks a new theme from the bottom sheet
- `SmartScannerWidgetState` is public — use `GlobalKey<SmartScannerWidgetState>` to call `showThemePicker()` from an external button (e.g. an `AppBar` action), guaranteeing pixel-perfect alignment with other AppBar widgets

**Themes**
- Three built-in themes:
  - `ScannerTheme.neon` — cyan glow, dark overlay (default)
  - `ScannerTheme.light` — white corners, sky-blue scan line (`#80DEEA`), lighter overlay, mint-green success
  - `ScannerTheme.minimal` — pure white corners, minimal overlay
- Fully custom theme via `ScannerTheme(...)` with `copyWith()` support
- Theme picker bottom sheet — white background, drag handle, palette icon header, animated selection rows with per-theme accent colour, checkmark indicator, close button

**Loading Screen**
- Modern animated loader with:
  - Glowing corner brackets that pulse (opacity breathing, blur glow layer)
  - Sweep scan line with gradient and glow, reversing back and forth
  - Pulsing QR icon in the centre of the frame
  - `PREPARING SCANNER` label with wide letter spacing in the theme accent colour
  - Sequential 3-dot indicator (each dot lights up and grows in turn)
  - Subtle `Starting camera…` subtitle

**Transitions**
- Scanner screen opens with a slide-up-from-bottom animation (`easeOutCubic`, 420 ms) combined with a fast fade-in over the first 40 % of the transition
- Back/dismiss uses a faster reverse transition (320 ms) for a natural feel
- Result screen transition uses a fade animation (400 ms)

**Feedback & Accessibility**
- Haptic vibration and audio beep on successful scan, configurable via `enableVibration` / `enableSound`
- Duplicate prevention with configurable time window (`duplicatePreventionWindow`)
- Configurable scan timeout with `onTimeout` callback
- In-memory scan history with configurable capacity (`maxHistoryItems`)
- Lifecycle-aware: auto-pauses on `AppLifecycleState.paused`, resumes on `AppLifecycleState.resumed`
- Built-in camera permission request flow with settings deep-link on permanent denial

**Platform Setup**
- Android: `minSdkVersion 21`, ML Kit `barcode_ui` meta-data, `CAMERA` permission
- iOS: `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` in `Info.plist`, `platform :ios, '14.0'`
