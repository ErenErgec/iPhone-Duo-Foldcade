# 🕹️ Retro Cartridge & Unfold (iPhone Duo)

> **Turn Apple's folding iPhone Duo into a tactile 90s handheld console.**

[![Platform](https://img.shields.io/badge/Platform-iOS%2027.0%2B-black?style=for-the-badge&logo=apple)](https://developer.apple.com)
[![Device](https://img.shields.io/badge/Target-iPhone%20Duo%20only-0071e3?style=for-the-badge)](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo)
[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?style=for-the-badge&logo=swift)](https://swift.org)
[![Framework](https://img.shields.io/badge/UI-SwiftUI-007AFF?style=for-the-badge&logo=swift)](https://developer.apple.com/xcode/swiftui/)
[![Rendering](https://img.shields.io/badge/Shaders-Metal-999999?style=for-the-badge&logo=apple)](https://developer.apple.com/metal/)
[![Monetization](https://img.shields.io/badge/StoreKit-2-34C759?style=for-the-badge)](https://developer.apple.com/storekit/)

---

## 🌟 Overview

**Retro Cartridge & Unfold** is built exclusively for the **iPhone Duo**. It treats the fold as part of the experience instead of just a bigger canvas:

- **Closed** (held with the hinge on top): the 5.4" outer display is a cartridge case. Swipe through cartridges and pick one.
- **Unfolded like a clamshell:** the 7.6" inner display becomes a Game Boy–style console, split exactly at the hinge. A curved CRT is above the hinge and a physical-feeling control deck is below. The cartridge chosen on the cover is inserted automatically, and folding again pauses the game.

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
4. **Vertical controls:** the app name, **Skins** and **Store** are standard toolbar items. iPhone Duo lays them out vertically in the column beside the camera and status bar, or as a top bar on the inner display in portrait. A running console hides the bars for an immersive screen.
5. **Hinge:** `onHingeChange` (iOS 27.1) drives the CRT curvature and an 8-bit chime with a haptic click when the hinge passes 90°. It is used for visuals only; layout uses reserved regions.
6. **Display detection by size:** `PostureManager` / `DuoDisplay` tell the outer display (≈678×466 pt) from the inner one (≈669×951 pt).

---

## 🎮 Games

All four games implement `PixelGameProtocol` and render at 60 FPS in a SwiftUI `Canvas` inside the CRT.

| Game | Description | Controls |
| :--- | :--- | :--- |
| **🧱 Brick Breaker** | Breakout with multi-ball and wide-paddle power-ups. | D-Pad ◀ ▶ moves the paddle. |
| **🏎️ Retro Racer** | Three-lane top-down highway dodge that speeds up over time. | D-Pad ◀ ▶ changes lanes. |
| **🐍 Snake** | Grid snake that speeds up every five apples. | D-Pad changes direction (no reversing). |
| **🧩 Falling Blocks** | Tetromino stacking with a ghost piece and line clears. | D-Pad ◀ ▶ ▼ moves, ▲ hard-drops, A / B rotates. |

- **All games:** A starts or retries, Start pauses, and Select ejects the cartridge back to the library.
- **High scores** are saved per game.
- **Sound:** every game plays chiptune effects from `AudioManager`, a 3-channel sequenced synth (pulse/triangle/noise) that renders on the audio thread. Big events also trigger a haptic.

---

## 📺 CRT shader

`CRTView.metal` is a stitchable shader applied to the game layer with SwiftUI's `layerEffect` (`CRTEffect.swift`). It adds:
- barrel curvature, driven by the hinge angle;
- chromatic aberration towards the edges;
- phosphor glow;
- scanlines;
- a vignette;
- a power-on beam animation at the start of every session.

---

## 🕹️ Controls & skins

- **Control deck:**
  - a 4-way D-Pad that tilts toward the pressed direction;
  - staggered A/B buttons;
  - Select/Start pills;
  - a speaker grille.
- **Input timing:** buttons fire on touch-down for low latency, and D-Pad releases are sent to the games.
- **Skins:** Classic Grey (free), Atomic Purple, Cyberpunk Neon and 90's Arcade Cabinet. Pick one with **Skins** in the system toolbar (on either display); the console restyles immediately and the choice is saved.

---

## 💎 In-app purchases (StoreKit 2)

**Store** in the system toolbar (on either display) sells two non-consumables:

| Product | ID | Price | Unlocks |
| :--- | :--- | :--- | :--- |
| Retro Collector Pack | `com.retrocartridge.collector_pack` | $6.99 | Atomic Purple, Cyberpunk Neon, 90's Arcade Cabinet |
| Lifetime Pro | `com.retrocartridge.lifetime_pro` | $49.99 | Every skin, plus future skins and cartridges |

All four games are free. `Products.storekit` defines both products for local testing, and the shared scheme uses it when you run from Xcode.

---

## 🗂️ Project structure

```
RetroCartridge/
├── RetroCartridge.xcodeproj           # Committed project (edit in Xcode or by hand, no generator)
├── Products.storekit                  # StoreKit test configuration
├── RetroCartridge/
│   ├── App/
│   │   ├── RetroCartridgeApp.swift    # @main UIKit entry, per-display orientation, RootView (NavigationStack)
│   │   └── AppState.swift             # @Observable app state: active game, skin, overlays, high scores
│   ├── Core/
│   │   ├── AudioManager.swift         # Sequenced 3-channel chiptune synth (AVAudioEngine)
│   │   ├── HapticManager.swift        # CoreHaptics transient feedback
│   │   ├── HingeEngine.swift          # Smoothed hinge angle (onHingeChange) + 90° unfold chime
│   │   └── PostureManager.swift       # Outer / inner display detection (DuoDisplay)
│   ├── Layout/
│   │   ├── AdaptiveConsoleLayout.swift # Cover vs inner routing, system toolbar, fold/unfold, hinge
│   │   ├── CoverScreenLayout.swift    # Outer display: cartridge carousel
│   │   └── FullScreenLayout.swift     # Inner display: library, console split at the fold (FoldSplit)
│   ├── Rendering/
│   │   ├── CRTView.metal              # CRT layer-effect shader
│   │   └── CRTEffect.swift            # SwiftUI bridge for the shader
│   ├── UI/
│   │   ├── GameCanvasView.swift       # CRT bezel, 60 FPS game loop, sound dispatch
│   │   ├── ControllerView.swift       # D-Pad, A/B, Select/Start
│   │   ├── CartridgeView.swift        # Cartridge artwork, backdrop
│   │   ├── SkinPickerView.swift       # Skin picker overlay
│   │   ├── StoreView.swift            # Store overlay
│   │   ├── OverlayPanel.swift         # Overlay panel chrome + LibraryOverlays (skin picker, store host)
│   │   └── Skins/                     # SkinTheme definitions + console previews
│   ├── Games/                         # PixelGameProtocol, factory, and the four games
│   ├── Models/GameModels.swift        # Game, input, posture, skin and sound types
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
Distributed under the MIT License. See `LICENSE` for more information.
