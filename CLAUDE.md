# CLAUDE.md

A SwiftUI + Metal game console app for **iPhone Duo only** (iOS 27, Swift 6 strict concurrency). The README covers features and structure. This file lists the rules that aren't obvious from the code.

## Build, run, test

```bash
# Build (from repo root)
xcodebuild -project RetroCartridge/RetroCartridge.xcodeproj -scheme RetroCartridge \
  -destination 'generic/platform=iOS Simulator' -configuration Debug build

# Unit tests: use a non-Duo iOS 27 simulator. `xcodebuild test` hangs on the iPhone Duo simulator.
xcodebuild -project RetroCartridge/RetroCartridge.xcodeproj -scheme RetroCartridge \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.0' test
```

- **Run on the Duo:**
  - Build with `-destination 'id=<iPhone Duo UDID>'`, then run `xcrun simctl install` and `xcrun simctl launch`.
  - The user often has the Duo open in Device Hub. Don't reboot, erase or reconfigure it.
- **Screenshots:** `xcrun simctl io <UDID> screenshot` captures the inner display, in interface orientation. It returns black frames while the device is folded. The outer display can't be captured this way.
- **UI that needs taps:** tool taps don't reach the inner display. Build a throwaway copy in a temp directory that sets the state at launch, e.g. launch arguments that call `appState.startGame(type:)` or open an overlay. Screenshot it, then reinstall the real build.
- **Editor errors:** SourceKit shows spurious "Cannot find 'AppState' in scope" errors. Trust `xcodebuild`.

## Project file

- There is no project generator. The committed `project.pbxproj` and the shared scheme (with the StoreKit config) are the source of truth. XcodeGen was removed because regenerating dropped settings.
- Add a new source file by hand: copy an existing file's four entries (PBXBuildFile, PBXFileReference, group child, Sources build phase) with fresh 24-hex IDs, or add it in Xcode.

## Invariants (each was learned the hard way)

- **Orientation must never rotate.** The user tested many approaches; see the commit history.
  - `ConsoleHostingController` (in `App/RetroCartridgeApp.swift`) sets `prefersInterfaceOrientationLocked` and supports all orientations.
  - `Layout/FixedOrientation.swift` counter-rotates content to a per-display design orientation: `.landscapeLeft` on the outer display, `.portrait` with `ignoresHalfTurns` on the inner display.
  - Do not reintroduce:
    - portrait-only Info.plist (iOS letterboxes the app);
    - `requestGeometryUpdate` (rotation animation);
    - size-class or aspect-ratio layout switching.
  - The design pose: closed with the hinge on top (outer display landscape), opened like a clamshell with the CRT above the hinge and the controller below.
  - Verify orientation from logs (`windowScene.effectiveGeometry.interfaceOrientation`, `isInterfaceOrientationLocked`), not by reasoning.
- **No UIKit-presented UI:** no `.sheet`, `.fullScreenCover`, `.alert`, `.confirmationDialog`, popovers or menus. They appear in the locked scene orientation, which is sideways relative to the pinned layout. Use in-hierarchy overlays like `UI/OverlayPanel.swift`. The system StoreKit purchase sheet is the only exception.
- **Inner display split:** it must sit exactly on the hinge. `FullScreenLayout.console` measures the full display, and each half applies `\.fixedSafeAreaInsets` itself.
- **Game Canvas redraw:** the `Canvas` in `UI/GameCanvasView.swift` must capture a per-frame value (`[frameDate = date]`). Otherwise SwiftUI treats the renderer as unchanged and the game looks frozen while it keeps running.
- **Games stay UI-free:** they don't touch `AudioManager` or haptics. They `emit(_:)` sounds into `pendingSounds`, and the frame loop drains them.
- **Audio thread safety:** `AudioManager` renders on the audio thread. No allocation or blocking there beyond the existing unfair lock.
- **Hinge angle:** there's no public API in iOS 27. `HingeEngine` derives it from the display posture. Use it only for visuals (CRT, chime), never for layout.
- **Status bar:** keep it visible. On iPhone Duo it lives in a system-reserved side column that apps can't draw into, and hiding it leaves an empty black strip.

## Conventions

- Code, comments and commit messages are in English. The user communicates in Turkish.
- Match the existing style: `// MARK:` sections, doc comments on types and non-trivial members, and `@Observable` managers injected through the SwiftUI environment in `RootView`.
- The app ships for iPhone Duo only. Don't add fallbacks for other devices.
