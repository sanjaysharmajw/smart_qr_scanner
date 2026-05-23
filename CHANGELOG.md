## 1.6.0

### New Features

**Holographic QR Overlay (`HolographicQrOverlay`)**
- New widget in the example app — renders the scanned QR code as a floating hologram immediately after a successful scan
- Entrance animation built with `TweenSequence`: scale bursts from `0.05×` → `1.18×` → `0.94×` → `1.0×` (small-to-big succession with overshoot settle)
- Opacity fades in during the first 25 % of the entrance so the scale growth is fully visible
- Continuous 3D tilt oscillation via `Matrix4` perspective transform (`rotateX` ± 0.30 rad, `rotateY` ± 0.22 rad, perspective 0.002) — hologram appears to float in space
- Entrance tilt: starts at 0.55 rad forward-lean and settles to 0 as the card rises into view
- Float animation: ±6 px vertical translation on a 2800 ms sine loop
- Slide-up entrance: card rises from +40 px below final position
- Cyan sweep scan line rendered by an isolated `_SweepPainter` (`CustomPainter`) — only the scan line repaints per tick, not the QR widget
- `ClipRRect` with `borderRadius: 10` clips QR edges cleanly
- `RepaintBoundary` wraps the card so tilt/float repaints are isolated from the rest of the tree
- `onDismiss` is optional — when `null` the parent (`SmartScannerWidget`) controls removal via `_showSuccess`
- Auto-dismiss with configurable `autoDismissAfter` duration when `onDismiss` is provided

**`ScanSuccessStyle.pixelBurst`**
- New enum value on `SmartScannerWidget.successStyle`; selects the Paytm-style white-pixel burst animation in place of the default ripple check-mark

**`successOverlayBuilder` parameter**
- `Widget Function(SmartScanResult)?` — renders any widget behind the success animation at the moment of scan
- Z-order: dark scrim (7a) → overlay (7b) → pixel burst (7c) — pixels always render on top

**`onScanAnimationComplete` callback**
- Fires after the success animation completes (pixel burst at t = 0.70); use this for navigation instead of `onScan` so the animation is never cut short by the screen being disposed

**`successLogo` / `successLogoSize` parameters**
- Optional `Widget?` centered inside the pixel burst; fades out in the second half of the animation

**Delayed pixel burst (`_showBurst` flag)**
- Hologram materialises first (0 ms); pixel burst starts 600 ms later so pixels visually emerge from the fully-formed hologram

**Camera auto-pause on scan**
- `controller.pause()` called the moment a scan is confirmed; `controller.resume()` called inside `onComplete` after animation ends — camera feed freezes during the success animation

**Dark scrim on scan success**
- Semi-transparent black overlay (`Colors.black.withAlpha(180)`) fades in (`300 ms`) behind the hologram so white QR modules are legible against any camera background

### Improvements

**Scan UI auto-hide**
- Scanner overlay (corner brackets + animated scan line), status label, and hint text are hidden as soon as `_detecting` becomes `true` when `successStyle == pixelBurst`, not only after `_showSuccess` — the frame disappears the instant a code is first detected
- All three items are restored when `_showSuccess` returns to `false`

**Pixel Burst — performance overhaul**
- `saveLayer` / `ImageFilter.blur` removed entirely — all blocks drawn directly via `canvas.drawRect`; no GPU-layer allocation per frame
- Single `Paint` object (`_p`) reused across every block every frame — eliminates ~15 600 `Paint` allocations per second at 60 fps with 260 blocks
- Flash shockwave also reuses `_p` (with `maskFilter` reset between circles)
- `_Cmd` bucket class and `_drawBlurred` helper removed (no longer needed)
- `dart:ui` import removed
- Block count reduced from 520 → 260
- `RepaintBoundary` wraps both the pixel burst and the holographic overlay — isolates their repaint from the rest of the scanner widget tree

**Pixel Burst — animation quality**
- `fadeStart` range `0.68–0.90` gives a long, gradual fade tail
- `onComplete` fires at `t ≥ 0.70` (blur phase start) for snappy navigation timing while animation still plays to completion naturally

**Holographic overlay — performance**
- `_sweepCtrl` (`1600 ms` repeat) drives only its own `AnimatedBuilder`; the QR widget and tilt/float tree are not rebuilt on sweep ticks
- Outer `AnimatedBuilder` uses `Listenable.merge([_entranceCtrl, _floatCtrl, _tiltCtrl])` and passes the card as a static `child:` — card widget tree is never rebuilt by animation ticks

### Removals

- **"Scanning paused" overlay and pause icon** removed from the scanner UI — the paused state is now fully silent

### Bug Fixes

- `_StatusLabel` no longer receives a `paused:` parameter after the paused state was removed — the stale call-site argument is cleaned up

---

## 1.5.0

### Bug Fixes

- **QR codes not scannable** — `QrView` was using `PrettyQrSmoothSymbol` which renders smooth/curved connections between modules that confuse QR readers. Switched to `PrettyQrSquaresSymbol` (standard sharp square modules) and added `PrettyQrQuietZone.standard` (mandatory 4-module quiet zone); generated codes are now reliably scanned by all standard QR readers.

### Removals

- **`share_plus` removed** — all sharing UI and logic removed from the main package and example app. `HistoryExporter.exportCsv()` now writes the CSV to the temporary directory and returns `true`/`false`; it no longer opens the system share sheet. Share buttons removed from the result screen and generator screen in the example app.
- **`QrPainter` / `buildQrImage()` removed** — custom painter replaced by `PrettyQrView` from `pretty_qr_code: ^3.6.0`. `QrView` now delegates to `PrettyQrView.data()` with `PrettyQrSquaresSymbol` for scannable output.

### Dependencies

| Change | Package | Details |
|--------|---------|---------|
| Added | `pretty_qr_code` | `^3.6.0` — replaces custom `QrPainter`; provides `PrettyQrView` for QR rendering |
| Removed | `qr` | Replaced by `pretty_qr_code` |
| Removed | `share_plus` | Sharing functionality removed from package |

---

## 1.4.0

### Improvements

- README updated with full feature documentation, platform setup guide, API reference, themes, troubleshooting, and performance tips



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
