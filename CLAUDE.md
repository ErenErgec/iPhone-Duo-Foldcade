# CLAUDE.md

A SwiftUI + Metal game console app for **iPhone Duo only** (deployment target and SDK iOS 27.1, Swift 6 strict concurrency). The README covers features and structure. This file lists the rules that aren't obvious from the code.

**Read `DESIGN.md` first for any layout, orientation, toolbar or hinge work.** It collects Apple's iPhone Duo guidance and our simulator measurements. Its §10 records the decisions made and what the user verified.

**Build with Xcode 27.1 or later.** With the 27.0 SDK the app runs in a legacy-like mode on iPhone Duo: no full screen, no vertical bars, and no Duo APIs.

## Build, run, test

```bash
# Build (from repo root)
xcodebuild -project RetroCartridge/RetroCartridge.xcodeproj -scheme RetroCartridge \
  -destination 'generic/platform=iOS Simulator' -configuration Debug build

# Unit tests: run on the iPhone Duo simulator (the iOS 27.1 runtime only supports iPhone Duo)
xcodebuild -project RetroCartridge/RetroCartridge.xcodeproj -scheme RetroCartridge \
  -destination 'platform=iOS Simulator,name=iPhone Duo,OS=27.1' test
```

- **Run on the Duo:**
  - Build with `-destination 'id=<iPhone Duo UDID>'`, then run `xcrun simctl install` and `xcrun simctl launch`.
  - The user often has the Duo open in Device Hub. Don't reboot, erase or reconfigure it.
- **Screenshots:** `xcrun simctl io <UDID> screenshot --display=1` captures the outer display and `--display=3` the inner one, both in interface orientation. A display that is off (e.g. the inner display while folded) returns black.
- **UI that needs taps:** tool taps don't reach the inner display. Build a throwaway copy in a temp directory that sets the state at launch, e.g. launch arguments that call `appState.startGame(type:)` or open an overlay. Screenshot it, then reinstall the real build.
- **Editor errors:** SourceKit shows spurious "Cannot find 'AppState' in scope" errors. Trust `xcodebuild`.

## Project file

- There is no project generator. The committed `project.pbxproj` and the shared scheme (with the StoreKit config) are the source of truth. XcodeGen was removed because regenerating dropped settings.
- Add a new source file by hand: copy an existing file's four entries (PBXBuildFile, PBXFileReference, group child, Sources build phase) with fresh 24-hex IDs, or add it in Xcode.

## Invariants (each was learned the hard way)

- **Orientation (decided 2026-09-23, option A in DESIGN.md §10):**
  - The outer display honors orientation masks. `ConsoleHostingController` locks it to `.landscapeLeft`, which puts the hinge on top.
  - The inner display ignores masks, per Apple. Its layout adapts to the system orientation instead: `FullScreenLayout` splits the console at the fold from `reservedRegions(kind: .division, options: .includeInactive)` (`FoldSplit`). That gives CRT above and controls below in portrait, and side by side in landscape.
  - Don't reintroduce `prefersInterfaceOrientationLocked` or counter-rotation (`FixedOrientation`, removed). Both only "worked" with the 27.0 SDK in legacy mode.
- **Overlays:** the skin picker and store are in-hierarchy overlays (`LibraryOverlays` in `UI/OverlayPanel.swift`), shown on both displays, to keep the retro look.
- **Inner display split:** it must sit exactly on the fold. `FullScreenLayout.console` measures the full display (ignoring the safe area) and pads each half with the safe area insets of its own outer edges.
- **Game Canvas redraw:** the `Canvas` in `UI/GameCanvasView.swift` must capture a per-frame value (`[frameDate = date]`). Otherwise SwiftUI treats the renderer as unchanged and the game looks frozen while it keeps running.
- **Games stay UI-free:** they don't touch `AudioManager` or haptics. They `emit(_:)` sounds into `pendingSounds`, and the frame loop drains them.
- **Audio thread safety:** `AudioManager` renders on the audio thread. No allocation or blocking there beyond the existing unfair lock.
- **Hinge angle:** it comes from `onHingeChange` (iOS 27.1), forwarded to `HingeEngine.updateFromHardware(_:)`, with the display posture as a fallback. Use it only for visuals (CRT, chime), never for layout; layout uses reserved regions.
- **System toolbar:** the root is wrapped in a `NavigationStack`. The app name is a `navigationTitle`, and Skins/Store are `Label` items (icon + title), so iPhone Duo can lay them out vertically in the side column. On the inner display in portrait they form a regular top bar.
  - The toolbar is hidden over a running console (immersive, no bars).
  - Text-only or custom-view items stay horizontal.
- **Appearance:** the window forces the dark style so system bars and titles read on the dark console.

## Project status (2026-09-23)

- **Git:** all work is on branch `gameplay-fixes`, open as PR #1 against `main` (`main` still holds only the initial scaffold). Commit and push only when the user asks; they usually test in Device Hub first.
- **Done and verified by the user on the simulator:**
  - games running at 60 FPS;
  - CRT shader;
  - Game Boy–style console, cartridge library, cover carousel;
  - Duo-native layout (outer display locked landscape, inner display adaptive fold split);
  - vertical toolbar;
  - real hinge angle and 90° chime.
- **Not yet verified:**
  - sound effects by ear (only rendered offline);
  - StoreKit purchases end to end (run from Xcode with `Products.storekit` selected in the scheme);
  - anything on real iPhone Duo hardware (ships 2026-10-23).
- **Possible next steps:** check sound and volume, test purchases, and consider Apple's recommendations not yet adopted, such as `ArrangementView`, the occlusion reserved region for the outer camera, and `visibilityPriority` for toolbar overflow.

## Conventions

- Code, comments and commit messages are in English. The user communicates in Turkish.
- Match the existing style: `// MARK:` sections, doc comments on types and non-trivial members, and `@Observable` managers injected through the SwiftUI environment in `RootView`.
- The app ships for iPhone Duo only. Don't add fallbacks for other devices.
