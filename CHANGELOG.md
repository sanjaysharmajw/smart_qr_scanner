## 1.3.0

### New Features

**QR Code Generator**
- Added `QrGeneratorWidget` — a full-featured QR code creator with no external rendering dependency
- Supports 6 input types: URL, plain text, WiFi credentials (WPA/WEP/None), email, phone number, and vCard contact
- Custom `QrPainter` (`CustomPainter`) renders the complete QR matrix including the mandatory 4-module quiet zone on all sides — generated codes are now reliably scannable by all standard readers
- `QrView` widget wraps `QrPainter` for simple drop-in usage
- `buildQrImage(String data) → QrImage?` top-level helper for programmatic access
- Accent-coloured finder patterns (eye regions); data modules rendered in solid black for maximum contrast
- Removed `qr_flutter` dependency; uses the lighter `qr: ^3.0.0` package directly

**Image Capture & Sharing**
- `RepaintBoundary` + `RenderRepaintBoundary.toImage(pixelRatio: 3.0)` captures the QR widget at 3× resolution as PNG bytes
- Save generated QR codes to the device photo gallery via the `gal` package (`Gal.putImageBytes`)
- Share generated QR codes as a PNG image with a date/time subject line via `share_plus` (`Share.shareXFiles`)

**Persistent Storage**
- Added `StorageService` — thin SharedPreferences wrapper for JSON-based persistence
- `HistoryService` now persists via `StorageService`; history is restored on every app launch
- `SmartScanResult.toJson()` / `SmartScanResult.fromJson()` — full round-trip serialization of all fields including enums (via index), `DateTime`, `Rect`, and `List<Offset>`

**Favorites**
- Added `FavoritesService` — persists favorited `rawValue` strings via `StorageService`
- `isFavorite(String rawValue)`, `toggle(String rawValue)`, `loadAll()` API
- Added `FavoriteButton` widget — drop-in animated bookmark button with a scale animation (`1.0 → 1.35`) on toggle; accepts `activeColor` override

**History Export**
- Added `HistoryExporter.exportCsv(List<SmartScanResult>)` — generates a UTF-8 CSV file with columns: `Timestamp`, `Format`, `Type`, `Raw Value`, `Display Value`, `Confidence`
- Writes to `getTemporaryDirectory()` and opens the system share sheet via `share_plus`

**URL Handler**
- Added `SmartUrlHandler` utility with three methods:
  - `canHandle(SmartScanResult)` — returns `true` for URL, email, phone, SMS, geo, and raw http/https values
  - `actionLabel(SmartScanResult)` — returns a human-friendly button label
  - `launch(SmartScanResult)` — opens the appropriate system handler via `url_launcher`

**Haptic Patterns**
- Added `HapticPattern` class with predefined patterns: `short`, `medium`, `long`, `doubleShort`, `tripleShort`
- `HapticPattern.forType(BarcodeType)` returns a pattern tailored to each barcode type (e.g., tripleShort for WiFi, doubleShort for email/phone, short for plain URL)
- `FeedbackService.scanSuccess` now accepts an optional `barcodeType` parameter and applies the matching pattern via `Vibration.vibrate(pattern: [...])`

**Duplicate Toast**
- Added `DuplicateToastOverlay` widget — wraps any child in a `Stack` and exposes `DuplicateToastOverlay.show(context, {String? message})`
- Toast fades in (`FadeTransition`), displays for 2 seconds, then fades out automatically

**Instant Camera Open**
- `ScannerScreen` now accepts an optional `SmartQrScannerController? controller` parameter
- When a pre-warmed controller is passed in, `initialize()` is not called again — the camera init overlaps with the route transition animation, eliminating the black-screen delay on open
- Navigation transition shortened to 280 ms (from 420 ms) with a matching 220 ms reverse

### Bug Fixes

- **Generated QR codes not scannable** — `QrPainter` was rendering the QR matrix edge-to-edge with no quiet zone; fixed by calculating `offset = quietZone * moduleSize` and shifting all module rects by that amount. Additionally removed `ClipRRect(borderRadius: 12)` from the capture boundary which was physically clipping the corner finder patterns
- **Data module opacity** — changed `dataColor` default from `Color(0xDD000000)` (87% opacity) to `Colors.black` for maximum contrast and reliable detection
- **Android manifest merger conflict** — `WRITE_EXTERNAL_STORAGE@maxSdkVersion` conflict with `camera_android_camerax` (value 28) fixed by adding `xmlns:tools` namespace and `tools:replace="android:maxSdkVersion"` to the permission element
- **iOS Simulator camera** — `availableCameras()` returns an empty list on the iOS Simulator (no physical camera hardware). The controller now detects `SIMULATOR_DEVICE_NAME` in `Platform.environment` and sets a sentinel error `'__ios_simulator__'`; `SmartScannerWidget` intercepts this and renders a dedicated teal info screen ("iOS Simulator — run on a real device") instead of the generic red error state
- **`DarwinAudioError` crash on dispose** — `audioplayers` removed entirely from the package. `FeedbackService.dispose()` is now a synchronous void method with no audio player teardown; `FeedbackService.scanSuccess()` no longer has a `sound` parameter

### Example App

- Complete UI redesign with a light theme (teal/cyan gradient `#00BCD4 → #006064`, white/off-white `#F0F7FF` backgrounds)
- Floating pill-style bottom navigation bar (4 tabs: Scan, History, Generate, Settings) implemented with `IndexedStack`
- **Scan tab**: gradient hero card, 6-mode feature grid, theme row, recent scans list
- **History tab**: inline (no separate screen push), search, swipe-to-delete, CSV export, clear confirmation sheet
- **Generate tab**: `QrGeneratorWidget` embedded in a white card with teal accent
- **Settings tab**: section cards with toggle rows and scan mode segmented control
- `ResultScreen` redesigned to light theme — teal gradient rounded header, white data cards, teal primary buttons, white secondary buttons side-by-side
- `FavoriteButton` added to `ResultScreen` AppBar and every history tile
- "Open URL / Call / Send Email" contextual action button in `ResultScreen` powered by `SmartUrlHandler`
- Share button in `ResultScreen` uses `Share.share(rawValue)` directly (was showing a SnackBar placeholder)

### Dependencies Added

| Package | Version | Purpose |
|---------|---------|---------|
| `gal` | `^2.3.0` | Save QR images to device gallery |
| `path_provider` | `^2.1.0` | Temporary directory for share file |
| `qr` | `^3.0.0` | QR matrix generation (replaces `qr_flutter`) |

### Dependencies Removed

| Package | Reason |
|---------|--------|
| `qr_flutter` | Replaced by a custom `QrPainter` using `qr` directly — removes Flutter rendering constraints and gives full control over quiet zone and module styling |
| `audioplayers` | Caused `DarwinAudioError` crash on iOS dispose. Feedback is now vibration-only via the `vibration` package; `FeedbackService` no longer plays audio |

---

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
- Front/back camera switch via `switchCamera()` — engine tracks `_currentFacing` separately from the immutable config to allow mid-session toggling
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
- `isSwitching` getter — true while the camera is being swapped

**UI — SmartScannerWidget**
- `showControls`, `showHint`, `showFlash`, `showGallery`, `showFlip`, `showMenu` — granular visibility toggles
- `onThemeChanged` — callback fired when the user picks a new theme
- `SmartScannerWidgetState` is public — use `GlobalKey<SmartScannerWidgetState>` to call `showThemePicker()` from an external button

**Themes**
- Three built-in themes: `ScannerTheme.neon`, `ScannerTheme.light`, `ScannerTheme.minimal`
- Fully custom theme via `ScannerTheme(...)` with `copyWith()` support
- Theme picker bottom sheet — drag handle, palette icon header, animated selection rows, checkmark indicator

**Loading Screen**
- Animated loader: glowing corner brackets, sweep scan line with glow, pulsing QR icon, `PREPARING SCANNER` label, sequential 3-dot indicator

**Transitions**
- Scanner screen: slide-up-from-bottom (`easeOutCubic`, 420 ms) + fast fade-in over first 40% of the transition
- Result screen: fade animation (400 ms)

**Feedback & Accessibility**
- Haptic vibration and audio beep on successful scan
- Duplicate prevention with configurable time window
- Configurable scan timeout with `onTimeout` callback
- In-memory scan history with configurable capacity
- Lifecycle-aware: auto-pauses on `AppLifecycleState.paused`, resumes on `AppLifecycleState.resumed`
- Built-in camera permission request flow with settings deep-link on permanent denial

**Platform Setup**
- Android: `minSdkVersion 21`, ML Kit `barcode_ui` meta-data, `CAMERA` permission
- iOS: `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` in `Info.plist`, `platform :ios, '14.0'`
