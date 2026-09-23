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

1. **One fixed pose, no rotation.**
   - The root `ConsoleHostingController` sets `prefersInterfaceOrientationLocked` (iOS 26+), so the system never rotates the app, or plays a rotation animation, when the device is folded or turned. Apple's HIG allows games to lock orientation.
   - `FixedOrientation` then pins each display's layout to the physical panel, whatever orientation the scene was locked in.
2. **Display detection by size.** `PostureManager` / `DuoDisplay` tell the outer display (≈466×678 pt) from the inner one (≈669×871 pt) using the full screen size. Size classes aren't used, because they change with orientation.
3. **Hinge angle for visuals only.**
   - iOS 27 has no public hinge-angle API. `HingeEngine` derives the angle from the display posture: outer = 0°, inner = 180°.
   - A spring smooths the change into a sweep that bends the CRT curvature, scanlines and vignette.
   - An 8-bit chime and haptic click play when the sweep passes 90° while unfolding.
   - The angle never drives layout.
4. **System side column.** iPhone Duo reserves a column on the side of each display for the camera, Dynamic Island and status bar. Apps can't draw there, so the app keeps the status bar visible there rather than leaving the column empty.
5. **No sheets or alerts.** UIKit presents these in the scene's locked orientation, not in the pinned layout's orientation, so they would appear sideways. The store and skin picker are in-hierarchy overlays instead.

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
- **Skins:** Classic Grey (free), Atomic Purple, Cyberpunk Neon and 90's Arcade Cabinet. Pick one from **SKINS** in the cartridge library; the console restyles immediately and the choice is saved.

---

## 💎 In-app purchases (StoreKit 2)

The **STORE** in the cartridge library sells two non-consumables:

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
│   │   ├── RetroCartridgeApp.swift    # @main UIKit entry, orientation-locked SwiftUI host, RootView
│   │   └── AppState.swift             # @Observable app state: active game, skin, overlays, high scores
│   ├── Core/
│   │   ├── AudioManager.swift         # Sequenced 3-channel chiptune synth (AVAudioEngine)
│   │   ├── HapticManager.swift        # CoreHaptics transient feedback
│   │   ├── HingeEngine.swift          # Hinge angle estimate + 90° unfold chime
│   │   └── PostureManager.swift       # Outer / inner display detection (DuoDisplay)
│   ├── Layout/
│   │   ├── AdaptiveConsoleLayout.swift # Routes to the cover or inner layout, fold/unfold behavior
│   │   ├── FixedOrientation.swift     # Pins a layout to its physical display
│   │   ├── CoverScreenLayout.swift    # Outer display: cartridge carousel
│   │   └── FullScreenLayout.swift     # Inner display: library, console, store/skin overlays
│   ├── Rendering/
│   │   ├── CRTView.metal              # CRT layer-effect shader
│   │   └── CRTEffect.swift            # SwiftUI bridge for the shader
│   ├── UI/
│   │   ├── GameCanvasView.swift       # CRT bezel, 60 FPS game loop, sound dispatch
│   │   ├── ControllerView.swift       # D-Pad, A/B, Select/Start
│   │   ├── CartridgeView.swift        # Cartridge artwork, backdrop
│   │   ├── SkinPickerView.swift       # Skin picker overlay
│   │   ├── StoreView.swift            # Store overlay
│   │   ├── OverlayPanel.swift         # Shared overlay panel chrome
│   │   └── Skins/                     # SkinTheme definitions + console previews
│   ├── Games/                         # PixelGameProtocol, factory, and the four games
│   ├── Models/GameModels.swift        # Game, input, posture, skin and sound types
│   └── Store/                         # StoreManager + product identifiers
└── RetroCartridgeTests/               # Unit tests
docs/                                  # Original planning documents (historical, not kept up to date)
```

---

## 🚀 Building & running

### Requirements
- Xcode 27 with the iOS 27 SDK and simulator runtime
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
Unit tests run on any iOS 27 iPhone simulator, e.g.:
```bash
xcodebuild -project RetroCartridge/RetroCartridge.xcodeproj -scheme RetroCartridge -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.0' test
```
`xcodebuild test` currently hangs on the iPhone Duo simulator, so use another device for tests.

---

## 📄 License
Distributed under the MIT License. See `LICENSE` for more information.
