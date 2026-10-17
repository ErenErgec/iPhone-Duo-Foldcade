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
- **Screenshots:** `xcrun simctl io <UDID> screenshot --display=1` and `--display=3` capture the two displays in interface orientation, but which number is which can swap between sessions: tell them apart by size (outer 2034×1398 px, inner 2007×2853 px, either way round). A display that is off (e.g. the inner display while folded) returns black.
- **UI that needs taps:** tool taps don't reach the inner display. Build a throwaway copy in a temp directory that sets the state at launch, e.g. launch arguments that call `appState.startGame(type:)` or open an overlay. Screenshot it, then reinstall the real build.
- **Editor errors:** SourceKit shows spurious "Cannot find 'AppState' in scope" errors. Trust `xcodebuild`.

## Project file

- There is no project generator. The committed `project.pbxproj` and the shared scheme (with the StoreKit config) are the source of truth. XcodeGen was removed because regenerating dropped settings.
- Add a new source file by hand: copy an existing file's four entries (PBXBuildFile, PBXFileReference, group child, Sources build phase) with fresh 24-hex IDs, or add it in Xcode.
- **Name (decided 2026-10-17):** the app ships as **Foldcade** (`CFBundleDisplayName` and the printed brand on the console, cartridges, library and intro). The bundle ID is `com.foldcade.app`, and the IAPs are `com.foldcade.collector_pack` and `com.foldcade.lifetime_pro`. These IDs are permanent once they exist in App Store Connect, so never change them. The project, target, module and folders keep the code name `RetroCartridge`. Keep "iPhone" and "Duo" out of the App Store name and subtitle (Apple trademarks).
- App Store settings: the app target is iPhone-only (`TARGETED_DEVICE_FAMILY = 1`) and signs with team `DBF2DNKP73`. `PrivacyInfo.xcprivacy` declares `UserDefaults` (reason `CA92.1`), no tracking and no collected data. If you start using another required-reason API (file timestamps, system boot time, disk space, keyboards), add it there.

## Invariants (each was learned the hard way)

- **Orientation (decided 2026-09-23, option A in DESIGN.md §10):**
  - The outer display honors orientation masks. `ConsoleHostingController` locks it to `.landscapeLeft`, which puts the hinge on top.
  - The inner display ignores masks, per Apple. Its layout adapts to the system orientation instead: `FullScreenLayout` splits the console at the fold from `reservedRegions(kind: .division, options: .includeInactive)` (`FoldSplit`). That gives CRT above and controls below in portrait, and side by side in landscape.
  - Don't reintroduce `prefersInterfaceOrientationLocked` or counter-rotation (`FixedOrientation`, removed). Both only "worked" with the 27.0 SDK in legacy mode.
- **Overlays:** the skin picker, screen settings, records and store are in-hierarchy overlays (`LibraryOverlays` in `UI/OverlayPanel.swift`), shown on both displays, to keep the retro look.
- **Occlusion:** custom interactive content outside the safe area (console halves, overlay panels) uses `.avoidingOcclusion()`, so an active camera pushes it aside. The console keeps `FoldSplit` rather than `ArrangementView` (DESIGN.md §10).
- **Inner display split:** it must sit exactly on the fold. `FullScreenLayout.console` measures the full display (ignoring the safe area) and pads each half with the safe area insets of its own outer edges.
- **Game Canvas redraw:** the `Canvas` in `UI/GameCanvasView.swift` must capture a per-frame value (`[frameDate = date]`). Otherwise SwiftUI treats the renderer as unchanged and the game looks frozen while it keeps running.
- **Randomness:** games draw every random choice from their `rng` (`GameRNG`), reseeded with `makeRNG()` in `reset()`. Never call `.random()` without `using: &rng`, or daily rounds stop being the same for everyone.
- **Games stay UI-free:** they don't touch `AudioManager` or haptics. They `emit(_:)` sounds into `pendingSounds`, and the frame loop drains them.
- **Game colors come from the palette:** `render` draws only with `palette` roles (`GamePalette`), never literal colors, so palettes can be swapped, even mid-round. Each game's native palette sits at the bottom of its file.
- **Cartridge metadata lives in `GameType.info`** (`CartridgeInfo`): subtitle, genre, artwork, label color, shell, modes, required product. A new game adds one case there, one in `PixelGameEngine`, one in `GamePalette.native(for:)` and one in `PixelArt.label(for:)`, plus a steering rule in `AttractPilot` (the attract test requires every game to score within 30 simulated seconds).
- **High scores:** `ProgressStore` keeps them per game and mode. The standard mode uses the pre-modes key `highScore_<Game>`, so never rename a shipped `GameMode.id`.
- **Screen modes:** one `screenEffect` shader draws every `ScreenMode`. Always draw `storeManager.effectiveScreenSettings(appState.screenSettings)`, never the stored settings directly, so locked modes and tuning fall back after a refund. Likewise draw the skin with `storeManager.effectiveSkin(appState.selectedSkin)` and play `effectiveSoundPack`.
- **Pause menu and eject:** while a game is paused, `ControllerView` routes the D-Pad and A / B to `PauseMenu` (Start still goes to the game). Select calls `appState.ejectCartridge()`; `GameCanvasView` plays the power-off and then calls `endGame()`. Don't call `endGame()` from the controller.
- **Attract mode:** `AttractPilot` plays games only through `handleInput` and reads their state. Keep games free of demo code.
- **Store contents:** gate an item only through its own `requiredProductID` (skins, `CartridgeInfo`, sound packs, screen modes). The store's lists and summaries are derived from it (`ProductIdentifiers`), and tests pin the split, so never hard-code store copy. Open the store for a locked item with `appState.openStore(highlighting:)`.
- **Achievements and sound packs:** achievement ids (`Achievement.id`) are persistence keys, like mode ids; never change a shipped one. Sound packs are baked into the note table at launch (`pack index × patch count + patch`), so adding a patch or pack needs no audio-thread change.
- **Music:** `ChipMusic` tempos must make a sixteenth a whole number of samples at 44.1 kHz (661500 divisible by the bpm; a test checks it), and every part of a track must span the same length, or the looping parts drift apart. Music plays only through `audioManager.playMusic(for:)`, which `GameCanvasView` calls every frame; sound packs keep music note lengths.
- **Sound switches:** music and sound effects turn off separately (`AppState.isMusicOn`, `isSoundOn`, both persisted, both in the pause menu). Every effect goes through `AudioManager.play(_:)`, which skips it while `areSoundEffectsOn` is false; add new effects there, never by triggering the generator directly. The audio session is `.ambient`, so the silent switch mutes the app.
- **Accessibility:** console controls go through `consoleControl(_:hint:press:release:)` (button trait plus `.allowsDirectInteraction`). The game screen's accessibility value comes from `screenDescription(for:)`; update it when a game gains a new state. Decorative views (brand, grille, attract mode) are hidden from accessibility.
- **Language (decided 2026-10-14):** the app ships in English only. The Turkish translation was removed because the pixel font (Silkscreen) has no ğ, ş, ı or İ; it is in git history (before this change) if it's ever needed again.
  - Strings still go through `Localizable.xcstrings` (English source): literals in `Text`, `Label`, `Button` and accessibility modifiers automatically, strings built in models with `String(localized:)`. Keep it that way so a translation can be added later.
  - Case with `uppercased()` / `capitalized` (English rules), never `localizedUppercase` / `localizedCapitalized`: on a device in a Turkish region those give İ, which the font lacks.
  - Don't add a language without a font that covers it; a test checks that no `tr.lproj` ships.
- **Cartridge labels:** `PixelArt` rows are 16×16 characters naming palette roles (key in `CartridgeArt.swift`); a test enforces the size and characters. Draw labels with `CartridgeArt`, which shows the player's own label from `appState.labels` (`LabelStore`) when there is one; never read `PixelArt.label(for:)` directly for display.
- **Intro:** `IntroView` sits above every overlay while `appState.isIntroVisible`. It opens by itself until `hasSeenIntro`; closing it at any point marks it seen. While it shows, unfolding doesn't insert the cartridge (its last page does), and `startGame` only hides it. Tests that touch `hasSeenIntro` restore the user's value.
- **Overlay text:** use `retroFont(_:weight:)` for text in overlays and the library, never a fixed `.font(.system(size:))`, so it follows Dynamic Type and Bold Text. It draws the bundled pixel font Silkscreen (OFL, `Resources/`, registered in `UIAppFonts`): Heavy and Black use Silkscreen Bold, everything else Regular. Pass `design:` only for SF Symbols. The console's printed text (bezel, tube, silkscreen, cartridge labels, and text games draw in `render`) uses `Font.pixel(_:bold:)` instead: fixed, scaling with the console. Use `bold: true` only for glyphs that stay open in Silkscreen Bold (not W, M, N).
  - Silkscreen has no ▲ ◀ ▶ ★ ☆ or ₺, so the system draws them from a fallback font. ◀ and ▶ fall back to color emoji: write `<` and `>` instead.
- **Motion:** decorative motion (neon pulse, attract mode, insert slide, console jolt) is skipped with Reduce Motion.
- **Library grid:** `LibraryGridMetrics` uses an even column count when the display has a fold (HIG: "prefer an even number of columns"). The fold is read with `.includeInactive`, so folding never reflows the grid. Cartridge width comes from the container, not a fixed size.
- **Audio thread safety:** `AudioManager` renders on the audio thread. No allocation or blocking there beyond the existing unfair lock.
- **Hinge angle:** it comes from `onHingeChange` (iOS 27.1), forwarded to `HingeEngine.updateFromHardware(_:)`, with the display posture as a fallback. Use it for visuals (CRT, chime) and as game input (Apple: "ideal for driving interactions or effects"), never for layout; layout uses reserved regions.
  - Games that take it conform to `HingeControllable` (Lunar Hinge). Every hinge action needs a button equivalent, so the game works in every pose.
- **System toolbar:** the root is wrapped in a `NavigationStack`. There is no `navigationTitle` (removed 2026-10-17: the brand is printed in the library header and on the console), and Skins/Store are `Label` items (icon + title), so iPhone Duo can lay them out vertically in the side column. On the inner display in portrait they form a regular top bar.
  - Items: two `ToolbarItemGroup`s, Skins, Screen and Labels (`.visibilityPriority(.high)`), then Store and Records. Skins, Screen, Labels and Records replace each other; the store stacks above them.
  - The toolbar is hidden over a running console (immersive, no bars).
  - Text-only or custom-view items stay horizontal.
- **Appearance:** the window forces the dark style so system bars and titles read on the dark console.

## Project status (2026-10-14)

- **Git:** `main` is the only branch. PR #1 (`gameplay-fixes`) was merged on 2026-09-28 and PR #2 (design and variety plan, App Store prep, pixel font) on 2026-10-14. The GitHub repo is private.
  - Commit and push only when the user asks; they usually test in Device Hub first.
  - The user merges PRs themselves: `gh pr merge` from Claude Code is blocked as a merge without review.
- **Done and verified by the user on the simulator (before the plan):**
  - games running at 60 FPS;
  - CRT shader;
  - Game Boy–style console, cartridge library, cover carousel;
  - Duo-native layout (outer display locked landscape, inner display adaptive fold split);
  - vertical toolbar;
  - real hinge angle and 90° chime.
- **Design and variety plan (Phases 0–7, all built and merged):**
  - Phase 0: role-based palettes, cartridge metadata, modes, `ProgressStore`, fold-aware library grid.
  - Phase 1: screen modes (CRT, LCD, Trinitron, Arcade) with tuning, skin finishes, cartridge shells and pixel-art labels, shelf, cover attract mode, insert and eject transitions, in-tube pause menu.
  - Phase 2: seeded games and daily rounds, mode picker, shared palettes, deeper original four games, five new cartridges (Pixel Invaders, Mine Sweep, Maze Muncher, Frog Hop, Lunar Hinge with hinge thrust), achievements, sound packs, four new skins.
  - Phase 3: store aligned with its contents (Maze Muncher, Frog Hop and Astro Drift in the Collector Pack; Lunar Hinge, Gold Edition, screen modes and tuning in Lifetime Pro), derived store copy, locked-item highlighting.
  - Phase 4: Records overlay, toolbar groups with visibility priorities, occlusion avoidance; `ArrangementView` evaluated and not adopted for the console.
  - Phase 5: a looping chiptune theme per cartridge, VoiceOver play and Reduce Transparency. Its Turkish localization was later removed (see Language).
  - Phase 6: label designer (Labels toolbar item), three new cartridges (Paddle Duel and Tower Stack free, Astro Drift in the Collector Pack), overlay text following Dynamic Type and Bold Text.
  - Phase 7: first-launch How to Play intro, replayable from Records.
- **App Store prep (2026-10-12 to 10-14):**
  - Release settings: iPhone-only device family, signing team, privacy manifest, no non-exempt encryption (see Project file).
  - App icon: a folding console with the app's own Octopus invader. The CoreGraphics script that draws it and the other drafts are in the git-excluded `TestReport/icon-drafts/`.
  - Silkscreen pixel font for overlay, library and console text, and English only (see Overlay text and Language).
  - A SOUND switch in the pause menu, separate from MUSIC (see Sound switches).
- **Verified on the simulator:**
  - 2026-09-30, end-to-end test pass: all unit tests, including StoreKit purchases, restore and refunds (`StoreKitPurchaseTests`); screenshots of every game and overlay on both displays (then in Turkish) and at accessibility text sizes; music rendered offline.
  - 2026-10-14: all 113 unit tests pass. Screenshots of the overlays, the library, the tube panels and the pause menu in Silkscreen look right on the inner display.
- **Not yet verified:**
  - the plan's visuals and interactions in Device Hub, in both inner-display orientations and on the cover;
  - Silkscreen on the outer display and at accessibility text sizes and with Bold Text (Bold cut);
  - Lunar Hinge played by folding (the simulator may not deliver hinge readings; ▲ / A always thrust);
  - sound effects, music, the four sound packs and the SOUND / MUSIC switches by ear (music was checked only by rendering it offline);
  - the label designer on both displays (drawing inside the scrolling panel on the cover), and the three new cartridges;
  - the intro on a fresh install (delete the app first), on the cover and after unfolding;
  - VoiceOver play on the console;
  - StoreKit purchases end to end (run from Xcode with `Products.storekit` selected in the scheme);
  - anything on real iPhone Duo hardware (ships 2026-10-23).
- **Before App Store submission:**
  - The installed Xcode 27.1 (27A9269) may be a beta, and App Store Connect rejects beta builds. Build with the released Xcode 27.1 (RC or GM).
  - App Store Connect: nothing is created yet, and the user signs in themselves. Set the primary language to English (U.S.), and set up the two non-consumable IAPs from `Products.storekit`, the privacy answers (no data collected), the age rating, iPhone Duo screenshots, and privacy policy and support URLs.
- **Possible next steps:**
  - Check the plan and the new font in Device Hub, including the toolbar overflow on the outer display (five items) and the console with the inner camera active.
  - Check sound and purchases.
  - Set up Game Center leaderboards (needs App Store Connect setup).
  - Maybe add a sound switch outside the pause menu (e.g. in the library toolbar).

## Conventions

- Code, comments and commit messages are in English. The user communicates in Turkish.
- Match the existing style: `// MARK:` sections, doc comments on types and non-trivial members, and `@Observable` managers injected through the SwiftUI environment in `RootView`.
- The app ships for iPhone Duo only. Don't add fallbacks for other devices.
- Don't add Claude as a contributor: no `Co-Authored-By: Claude` trailer in commit messages.
