# 🕹️ Foldcade (iPhone Duo)

> **Turn Apple's folding iPhone Duo into a tactile 90s handheld console.**

[![Platform](https://img.shields.io/badge/Platform-iOS%2027.1%2B-black?style=for-the-badge&logo=apple)](https://developer.apple.com)
[![Device](https://img.shields.io/badge/Target-iPhone%20Duo%20only-0071e3?style=for-the-badge)](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo)
[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?style=for-the-badge&logo=swift)](https://swift.org)
[![Framework](https://img.shields.io/badge/UI-SwiftUI-007AFF?style=for-the-badge&logo=swift)](https://developer.apple.com/xcode/swiftui/)
[![Rendering](https://img.shields.io/badge/Shaders-Metal-999999?style=for-the-badge&logo=apple)](https://developer.apple.com/metal/)
[![Monetization](https://img.shields.io/badge/StoreKit-2-34C759?style=for-the-badge)](https://developer.apple.com/storekit/)

---

## 🌟 Overview

**Foldcade** is built exclusively for the **iPhone Duo**. It treats the fold as part of the experience instead of just a bigger canvas:

- **Closed** (held with the hinge on top): the 5.4" outer display is a cartridge case. Swipe through cartridges and pick one.
- **Unfolded like a clamshell:** the 7.6" inner display becomes a Game Boy–style console, split exactly at the hinge. A curved CRT is above the hinge and a physical-feeling control deck is below. The cartridge chosen on the cover is inserted automatically, and folding again pauses the game. Unfolding resumes it, unless you picked another cartridge on the cover meanwhile: then the paused round ends (its score counts) and the new one goes in.

```
┌──────────────────────────────┬──────────────────────────────┐
│    5.4" Outer Display        │      7.6" Inner Display      │
│   • Landscape, hinge on top  │   • Portrait, hinge centered │
│   • Cartridge carousel       │   • Upper half: CRT screen   │
│   • "Unfold to Play"         │   • Lower half: controller   │
└──────────────────────────────┴──────────────────────────────┘
```

---

## 📐 How the iPhone Duo integration works

See [DESIGN.md](DESIGN.md) for Apple's guidance and our measurements.

1. **Full screen:** built with the iOS 27.1 SDK, so the app extends to every edge of both displays, including under the status bar and camera column.
2. **Outer display:** locked to the landscape orientation that puts the hinge on top. iPhone Duo honors orientation locks on the outer display.
3. **Inner display:** iPhone Duo doesn't honor orientation locks here, so the console adapts. It splits exactly at the fold, using the fold's reserved region: CRT above and controls below in portrait (the laptop/clamshell pose), side by side in landscape (book pose).
4. **Vertical controls:** **Skins**, **Screen**, **Labels**, **Store** and **Records** are standard toolbar items, in two groups with visibility priorities for overflow. iPhone Duo lays them out vertically in the column beside the camera and status bar, or as a top bar on the inner display in portrait. A running console hides the bars for an immersive screen.
5. **Hinge:** `onHingeChange` (iOS 27.1) drives the CRT curvature, an 8-bit chime with a haptic click when the hinge passes 90°, and Lunar Hinge's thrust (with a button equivalent). It is never used for layout; layout uses reserved regions.
6. **Camera:** the console halves and overlay panels move aside from an active camera using `.occlusion` reserved regions (`avoidingOcclusion()`).
7. **Display detection by size:** `PostureManager` / `DuoDisplay` tell the outer display (≈678×466 pt) from the inner one (≈669×951 pt).

---

## 🎮 Games

All twelve games implement `PixelGameProtocol` and render at 60 FPS in a SwiftUI `Canvas` inside the CRT.

| Game | Description | Modes | Controls |
| :--- | :--- | :--- | :--- |
| **🧱 Brick Breaker** | Twelve hand-built walls with tough and steel bricks; wide paddle, multi-ball, laser and sticky power-ups. | Standard | ◀ ▶ move, A launches the ball / fires the laser |
| **🏎️ Retro Racer** | Three-lane highway dodge with coins and a speedometer. | Day, Night (headlights only) | ◀ ▶ change lanes |
| **🐍 Snake** | Grid snake with a gold bonus every seventh apple. | Classic, Wrap, Maze | D-Pad steers |
| **🧩 Falling Blocks** | Tetromino stacking with a ghost piece and a three-piece preview. | Marathon, Sprint (40 lines), Ultra (2 min) | ◀ ▶ ▼ move, ▲ hard-drops, A / B rotate |
| **👾 Pixel Invaders** | A marching formation, eroding shields and a bonus saucer. | Standard | ◀ ▶ move, A fires |
| **💣 Mine Sweep** | A 10 × 9 minefield; the first reveal is always safe. | Standard | D-Pad moves the cursor, A reveals, B flags |
| **🟡 Maze Muncher** | Pellets, power pellets and three ghosts with different hunting styles. | Standard | D-Pad steers |
| **🐸 Frog Hop** | Traffic, river logs and five homes, against the clock. | Standard | D-Pad hops |
| **🌙 Lunar Hinge** | Land on one of three pads (×1, ×2, ×4). **Fold the device to thrust**, or hold ▲ / A. | Standard | fold or ▲ / A thrust, ◀ ▶ side thrusters |
| **🏓 Paddle Duel** | Table tennis against the computer: the hit point sets the angle, a moving paddle adds spin, and the computer gets quicker every level. | Match, Squash (against a wall) | ◀ ▶ move |
| **☄️ Astro Drift** | A vector ship in a wrapping field of rocks that split when hit; each cleared field brings a bigger wave. | Standard | ◀ ▶ turn, ▲ thrust, A fires, B hyperspace |
| **🏗️ Tower Stack** | Drop the sliding block on the tower; overhangs are cut off, perfect drops keep the width and a streak grows it back. | Standard | A or ▼ drops |

Every game also has a **Daily** mode: the same round for everyone that day (seeded from the UTC date), with a high score that starts over daily. The title and game-over screens switch modes with ◀ ▶.

- **All games:** A starts or retries, Start pauses, and Select ejects the cartridge (the tube powers off, then the library returns).
- **Pause menu:** while paused, an on-screen menu inside the tube offers Resume, Screen (switch between unlocked screen modes), Palette and Eject. The D-Pad moves and changes, A selects, B or Start resumes.
- **Attract mode:** on the cover screen, the selected cartridge plays itself faintly behind the details (`AttractPilot`), silently and at 30 FPS. It stays still with Reduce Motion.
- **High scores** are saved per game and mode (`ProgressStore`).
- **Achievements:** five per cartridge (first points, a level goal, a score goal, a daily round, every mode). New ones are announced on the bezel; cartridge labels show earned stars.
- **Records:** the Records toolbar item shows every cartridge's best score per mode (today's for Daily) and its achievements.
- **Palettes:** Original, DMG Green, Pocket Grey, Virtual Red and Neon Night recolor any game (PALETTE in the pause menu).
- **Sound:** every game plays chiptune effects from `AudioManager`, a sequenced synth (pulse/triangle/noise) that renders on the audio thread. Big events also trigger a haptic. Sound packs (Classic, Pocket, Arcade, Mellow) re-voice every sound; pick one in the skin picker.
- **Music:** each cartridge has its own looping eight-bar theme (lead, triangle bass, noise drums) on three music channels of its own, so effects never cut it. It plays on the title screen and in game, in the current sound pack, and stops on pause and game over. MUSIC in the pause menu turns it off, and SOUND turns off the sound effects (games and console) on their own. Both are remembered, and the ring/silent switch silences everything.

---

## 📺 Screen modes

`CRTView.metal` is a stitchable `screenEffect` shader applied to the game layer with SwiftUI's `layerEffect` (`CRTEffect.swift`). Pick a mode with **Screen** in the system toolbar or from the pause menu:

| Mode | Look |
| :--- | :--- |
| **Color CRT** (free) | Barrel curvature driven by the hinge angle, chromatic aberration, phosphor glow, scanlines, vignette |
| **Pocket LCD** | Flat four-shade green dot matrix with a pixel grid and pixels casting shadows on the backplate |
| **Trinitron** | Cylindrical tube, vertical RGB aperture grille and the two faint damper wires |
| **Arcade Monitor** | Deeper curve, thick scanlines and bloom |

- Tuning sliders scale curvature, lines and bleed (0.5 is each mode's designed look).
- Every session starts with a power-on beam; ejecting plays it in reverse. The LCD fades in and out from its backplate.

---

## 🕹️ Controls & skins

- **Control deck:**
  - a 4-way D-Pad that tilts toward the pressed direction;
  - staggered A/B buttons;
  - Select/Start pills;
  - a speaker grille.
- **Input timing:** buttons fire on touch-down for low latency, and D-Pad releases are sent to the games.
- **Skins:** pick one with **Skins** in the system toolbar (on either display); the console restyles immediately and the choice is saved. Each has its own shell finish (`ShellSurface`), bezel and power LED:
  - Classic Grey (free): grainy matte plastic;
  - Atomic Purple: translucent plastic over a circuit board;
  - Cyberpunk Neon: glossy black with a breathing neon edge that follows the display's corners;
  - 90's Arcade Cabinet: wood-grain laminate.
- **Menu colors:** the library and the cover are the outside of the device, so they're drawn as the equipped skin's case (its `ShellSurface`, finish included), with text in the skin's print color. The overlay panels are its screens: a dark panel tone and an accent chosen to read on it (`MenuTheme` in `SkinTheme.menu`: orchid for Atomic Purple, cyan for Cyberpunk Neon, gold for the Arcade Cabinet, and so on). The default, Classic Grey, is the original handheld: a grey case, and panels in its green LCD (the lightest green on the darkest) framed by the grey case with the big bottom-right corner, the magenta and navy stripes and a red power LED. The selected cartridge still tints the glow, and amber and alert red keep their meaning.
- **Cartridges:** each game has its own plastic (grey, off-white, black, glow-in-the-dark, clear over its circuit board) and a 16×16 pixel-art label drawn in the game's palette. The library stands them on a shelf with a collection counter; locked cartridges look dusty and open the store.
- **Intro:** the first launch opens a five-page *How to Play* on whichever display the app opens on: picking a cartridge, unfolding, the controls, ejecting and customizing. Unfolding waits for it; its last button inserts the cartridge. **How to Play** in Records shows it again.
- **Label designer:** **Labels** in the system toolbar (or *Design Label* in a cartridge's context menu) opens a 16×16 editor in the cartridge's palette: draw and fill, erase, mirror, undo, clear, or go back to the original. Every stroke is saved and the new label shows everywhere the cartridge appears.

- **Accessibility:**
  - VoiceOver: the controls are buttons with the direct-interaction trait, so games can be played by touch; a double tap presses a button, and the D-Pad has Up/Down/Left/Right actions for single steps. The game screen describes the game in words (title screen, score and level, pause menu, final score), and new achievements are announced.
  - Reduce Motion skips decorative motion; Reduce Transparency draws translucent shells solid, turns off the faded attract mode and makes overlay backdrops nearly opaque.
- **Text size and Bold Text:** overlay and library text follows Dynamic Type and Bold Text, and wraps rather than shrinking at accessibility sizes. The console's printed text scales with the console.
- **Language:** English, from a String Catalog (`Localizable.xcstrings`), so translations can be added later.
- **Type:** overlay and library text uses the pixel font [Silkscreen](https://github.com/googlefonts/silkscreen) by Jason Kottke (SIL Open Font License 1.1, license in `Resources/Silkscreen-OFL.txt`), sized with Dynamic Type and Bold Text.

---

## 💎 In-app purchases (StoreKit 2)

**Store** in the system toolbar (on either display) sells one non-consumable:

| Product | ID | Price | Unlocks |
| :--- | :--- | :--- | :--- |
| Foldcade Pro | `com.foldcade.pro` | $7.99 | The Maze Muncher, Frog Hop, Astro Drift and Lunar Hinge cartridges, 7 skins (all but Classic Grey), the Pocket, Arcade and Mellow sound packs, and the LCD, Trinitron and Arcade screen modes with tuning |

- **No promise of future content:** a later paid item joins Pro only if it names `ProductIdentifiers.pro` as its `requiredProductID`.

- **Free:** eight cartridges (Brick Breaker, Retro Racer, Snake, Falling Blocks, Pixel Invaders, Mine Sweep, Paddle Duel, Tower Stack), every mode, every palette, Classic Grey, Color CRT and the Classic sound pack.
- **Derived contents:** each item names the product that unlocks it (`requiredProductID`), and the store builds its lists and descriptions from those (`ProductIdentifiers.summary(for:)`), so it always shows exactly what a purchase opens.
- **Locked items:** locked cartridges look dusty on the shelf and say FOLDCADE PRO. Tapping anything locked opens the store with the product that unlocks it highlighted. Locked cartridges still play in the cover's attract mode. `Products.storekit` defines the product for local testing, and the shared scheme uses it when you run from Xcode.

---

## 🗂️ Project structure

The app ships as **Foldcade** (bundle ID `com.foldcade.app`). The Xcode project, target, module and folders keep the original code name `RetroCartridge`.

```
RetroCartridge/
├── RetroCartridge.xcodeproj           # Committed project (edit in Xcode or by hand, no generator)
├── Products.storekit                  # StoreKit test configuration
├── RetroCartridge/
│   ├── App/
│   │   ├── RetroCartridgeApp.swift    # @main UIKit entry, per-display orientation, RootView (NavigationStack)
│   │   └── AppState.swift             # @Observable app state: active game, skin, overlays, high scores
│   ├── Core/
│   │   ├── AudioManager.swift         # Six-channel chiptune synth (AVAudioEngine): effects, sound packs, looping music
│   │   ├── ChipMusic.swift            # Each cartridge's theme as text scores, parsed into looping patches
│   │   ├── HapticManager.swift        # CoreHaptics transient feedback
│   │   ├── HingeEngine.swift          # Smoothed hinge angle (onHingeChange) + 90° unfold chime
│   │   ├── PostureManager.swift       # Outer / inner display detection (DuoDisplay)
│   │   ├── ProgressStore.swift        # High scores per game and mode (daily ones reset), achievements
│   │   ├── LabelStore.swift           # The player's own cartridge labels
│   │   └── Achievements.swift         # Achievement definitions and per-frame tracker
│   ├── Layout/
│   │   ├── AdaptiveConsoleLayout.swift # Cover vs inner routing, system toolbar, fold/unfold, hinge
│   │   ├── CoverScreenLayout.swift    # Outer display: cartridge carousel
│   │   ├── FullScreenLayout.swift     # Inner display: library, console split at the fold (FoldSplit)
│   │   └── OcclusionAvoidance.swift   # Moves custom content aside from an active camera
│   ├── Rendering/
│   │   ├── CRTView.metal              # Screen-mode layer-effect shader (CRT, LCD, Trinitron, Arcade)
│   │   ├── CRTEffect.swift            # SwiftUI bridge for the shader
│   │   ├── ShellFinish.metal          # Matte grain and wood-grain color effects for shells
│   │   └── GamePalette.swift          # Role-based game colors (each game's palette sits in its file)
│   ├── UI/
│   │   ├── GameCanvasView.swift       # CRT bezel, 60 FPS game loop, sound dispatch
│   │   ├── ControllerView.swift       # D-Pad, A/B, Select/Start
│   │   ├── CartridgeView.swift        # Cartridge shell and label, backdrop
│   │   ├── CartridgeArt.swift         # 16×16 pixel-art labels in each game's palette
│   │   ├── AttractScreen.swift        # Cover attract mode (a game playing itself)
│   │   ├── PauseMenu.swift            # In-tube pause menu (input logic + on-screen display)
│   │   ├── ScreenSettingsView.swift   # Screen mode picker and tuning overlay
│   │   ├── RecordsView.swift          # High scores per mode and achievements overlay
│   │   ├── LabelDesignerView.swift    # 16×16 cartridge label editor overlay
│   │   ├── IntroView.swift            # First-launch How to Play pages
│   │   ├── RetroTypography.swift      # retroFont: Silkscreen pixel font, Dynamic Type and Bold Text
│   │   ├── SkinPickerView.swift       # Skin picker overlay
│   │   ├── StoreView.swift            # Store overlay
│   │   ├── OverlayPanel.swift         # Overlay panel chrome + LibraryOverlays (skin picker, store host)
│   │   └── Skins/                     # SkinTheme definitions, ShellSurface finishes, console previews
│   ├── Games/                         # PixelGameProtocol, factory, GameRNG, AttractPilot, and the twelve games
│   ├── Models/GameModels.swift        # Game, cartridge metadata, mode, input, posture, skin and sound types
│   ├── Localizable.xcstrings          # String Catalog (English)
│   ├── Resources/                     # Silkscreen pixel font (Regular, Bold) and its OFL license
│   └── Store/                         # StoreManager + product identifiers
└── RetroCartridgeTests/               # Unit tests
DESIGN.md                              # iPhone Duo platform reference: Apple guidance + measurements
docs/                                  # Original planning documents (historical, not kept up to date)
```

---

## 🚀 Building & running

### Requirements
- **Xcode 27.1 or later** with the iOS 27.1 SDK and simulator runtime. Earlier SDKs don't get full-screen layout, vertical bars or the Duo APIs; see [DESIGN.md](DESIGN.md).
- The **iPhone Duo** simulator
- Metal Toolchain (`xcodebuild -downloadComponent MetalToolchain`) if Xcode asks for it

### Run
```bash
git clone https://github.com/ErenErgec/iPhone-Duo-RetroCartridge.git
open iPhone-Duo-RetroCartridge/RetroCartridge/RetroCartridge.xcodeproj
```
1. Select the **iPhone Duo** simulator and press **⌘R**.
2. In **Device Hub**, fold and unfold the device and turn it, to check the cover and inner layouts and the unfold chime.
3. To test purchases, run from Xcode and make sure *Edit Scheme → Run → Options → StoreKit Configuration* is set to `Products.storekit`.

### Tests
```bash
xcodebuild -project RetroCartridge/RetroCartridge.xcodeproj -scheme RetroCartridge -destination 'platform=iOS Simulator,name=iPhone Duo,OS=27.1' test
```
The iOS 27.1 simulator runtime only supports iPhone Duo.

---

## 📄 License
Distributed under the MIT License. See `LICENSE` for more information. The bundled Silkscreen font is licensed separately under the SIL Open Font License 1.1 (`RetroCartridge/RetroCartridge/Resources/Silkscreen-OFL.txt`).
