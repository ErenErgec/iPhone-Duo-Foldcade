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
- **Randomness:** games draw every random choice from their `rng` (`GameRNG`), reseeded with `makeRNG()` in `reset()`. Never call `.random()` without `using: &rng`, or daily rounds stop being the same for everyone.
- **Games stay UI-free:** they don't touch `AudioManager` or haptics. They `emit(_:)` sounds into `pendingSounds`, and the frame loop drains them.
- **Game colors come from the palette:** `render` draws only with `palette` roles (`GamePalette`), never literal colors, so palettes can be swapped, even mid-round. Each game's native palette sits at the bottom of its file.
- **Cartridge metadata lives in `GameType.info`** (`CartridgeInfo`): subtitle, genre, artwork, label color, shell, modes, required product. A new game adds one case there, one in `PixelGameEngine`, one in `GamePalette.native(for:)` and one in `PixelArt.label(for:)`, plus a steering rule in `AttractPilot` (the attract test requires every game to score within 30 simulated seconds).
- **High scores:** `ProgressStore` keeps them per game and mode. The standard mode uses the pre-modes key `highScore_<Game>`, so never rename a shipped `GameMode.id`.
- **Screen modes:** one `screenEffect` shader draws every `ScreenMode`. Always draw `storeManager.effectiveScreenSettings(appState.screenSettings)`, never the stored settings directly, so locked modes and tuning fall back after a refund.
- **Pause menu and eject:** while a game is paused, `ControllerView` routes the D-Pad and A / B to `PauseMenu` (Start still goes to the game). Select calls `appState.ejectCartridge()`; `GameCanvasView` plays the power-off and then calls `endGame()`. Don't call `endGame()` from the controller.
- **Attract mode:** `AttractPilot` plays games only through `handleInput` and reads their state. Keep games free of demo code.
- **Store contents:** gate an item only through its own `requiredProductID` (skins, `CartridgeInfo`, sound packs, screen modes). The store's lists and summaries are derived from it (`ProductIdentifiers`), and tests pin the split, so never hard-code store copy. Open the store for a locked item with `appState.openStore(highlighting:)`.
- **Achievements and sound packs:** achievement ids (`Achievement.id`) are persistence keys, like mode ids; never change a shipped one. Sound packs are baked into the note table at launch (`pack index × patch count + patch`), so adding a patch or pack needs no audio-thread change.
- **Cartridge labels:** `PixelArt` rows are 16×16 characters naming palette roles (key in `CartridgeArt.swift`); a test enforces the size and characters.
- **Motion:** decorative motion (neon pulse, attract mode, insert slide, console jolt) is skipped with Reduce Motion.
- **Library grid:** `LibraryGridMetrics` uses an even column count when the display has a fold (HIG: "prefer an even number of columns"). The fold is read with `.includeInactive`, so folding never reflows the grid. Cartridge width comes from the container, not a fixed size.
- **Audio thread safety:** `AudioManager` renders on the audio thread. No allocation or blocking there beyond the existing unfair lock.
- **Hinge angle:** it comes from `onHingeChange` (iOS 27.1), forwarded to `HingeEngine.updateFromHardware(_:)`, with the display posture as a fallback. Use it for visuals (CRT, chime) and as game input (Apple: "ideal for driving interactions or effects"), never for layout; layout uses reserved regions.
  - Games that take it conform to `HingeControllable` (Lunar Hinge). Every hinge action needs a button equivalent, so the game works in every pose.
- **System toolbar:** the root is wrapped in a `NavigationStack`. The app name is a `navigationTitle`, and Skins/Store are `Label` items (icon + title), so iPhone Duo can lay them out vertically in the side column. On the inner display in portrait they form a regular top bar.
  - Items: Skins, Screen, Store in one `ToolbarItemGroup`. Skins and Screen replace each other; the store stacks above both.
  - The toolbar is hidden over a running console (immersive, no bars).
  - Text-only or custom-view items stay horizontal.
- **Appearance:** the window forces the dark style so system bars and titles read on the dark console.

## Project status (2026-09-28)

- **Git:** PR #1 (`gameplay-fixes`) was merged into `main` on 2026-09-28; `main` is the working branch. The GitHub repo is private. Commit and push only when the user asks; they usually test in Device Hub first.
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
- Don't add Claude as a contributor: no `Co-Authored-By: Claude` trailer in commit messages.
