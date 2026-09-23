# 🕹️ Retro Cartridge & Unfold (iPhone Duo)

> **Transform Apple's dual-screen folding flagship into an authentic, tactile 90s handheld retro console.**

[![Platform](https://img.shields.io/badge/Platform-iOS%2027.0%2B-black?style=for-the-badge&logo=apple)](https://developer.apple.com)
[![Device](https://img.shields.io/badge/Target-iPhone%20Duo-0071e3?style=for-the-badge)](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo)
[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?style=for-the-badge&logo=swift)](https://swift.org)
[![Framework](https://img.shields.io/badge/UI-SwiftUI-007AFF?style=for-the-badge&logo=swift)](https://developer.apple.com/xcode/swiftui/)
[![Rendering](https://img.shields.io/badge/Shaders-Metal%203-999999?style=for-the-badge&logo=apple)](https://developer.apple.com/metal/)
[![Monetization](https://img.shields.io/badge/StoreKit-2.0-34C759?style=for-the-badge)](https://developer.apple.com/storekit/)

---

## 🌟 Overview & Vision

**Retro Cartridge & Unfold** is an iOS application meticulously engineered for Apple's folding flagship, the **iPhone Duo**. Instead of viewing the foldable form factor as merely an enlarged canvas, this app embraces the physical ergonomics of the device to recreate the magic of classic cartridges and dual-screen retro handheld consoles (Game Boy Advance SP, Nintendo DS, and retro CRTs).

When folded closed, the device acts as a sleek cartridge case on the outer **5.4" cover display**. Unfolding the device dynamically morphs the hardware into a dedicated dual-screen console on the inner **7.6" display**: the upper panel becomes an authentic curved CRT television display, and the lower panel serves as an ultra-responsive physical retro gamepad with mechanical tactile feedback.

---

## 📐 Apple Human Interface Guidelines (HIG) Architecture

The app strictly adheres to Apple’s official **Designing for iPhone Duo** guidelines and WWDC architecture specifications:

```
┌─────────────────────────────────────────────────────────────┐
│                 iPhone Duo Layout Paradigm                   │
├──────────────────────────────┬──────────────────────────────┤
│    5.4" Outer Display        │      7.6" Inner Display      │
│     (Cover Screen)           │      (Full Dual Panel)       │
│   • Landscape, hinge on top  │   • Portrait, hinge centered │
│   • Cartridge Selection      │   • Upper half: CRT Canvas   │
│   • "Unfold to Play" prompt  │   • Lower half: Gamepad      │
└──────────────────────────────┴──────────────────────────────┘
```

1. **One Fixed Pose, No Rotation (HIG: games may lock orientation):**
   - The console is held closed with the hinge on top and opened like a clamshell handheld. The inner display splits exactly at the hinge: CRT above, controller below.
   - The root view controller locks the scene's interface orientation (`prefersInterfaceOrientationLocked`, iOS 26+), so iOS never rotates the app or animates a rotation while folding or turning the device. `FixedOrientation` then pins each display's layout to the panel — landscape with the hinge on top on the outer display, portrait with the hinge across the middle on the inner display — whatever orientation the scene was locked in.
   - Which display is active is determined from the display's size (`PostureManager` / `DuoDisplay`); the hinge angle is **never** used to drive layout.
2. **Hinge Angle for Continuous Visual Effects Only:**
   - `HingeEngine` supplies real-time, normalized hinge rotation (`0.0°` to `180.0°`) directly to the Metal CRT shader's arguments to modulate CRT curvature, glass barrel distortion, and scanline depth continuously as the user folds or unfolds the device.
3. **Reserved Regions API Adaptation:**
   - Wrapped by `ReservedRegionManager` to ensure zero critical game elements or controls collide with the physical hinge division and front camera occlusion boundaries.
4. **Swift 6 Strict Concurrency & Modern Lifecycle:**
   - Implements `@Observable` state macro.
   - CoreAudio synthesis is fully decoupled from the `@MainActor` thread using thread-safe non-isolated lock guards (`os_unfair_lock`) to prevent audio dropouts and queue assertion failures.

---

## 🎮 Included Mini-Games Catalog

All four mini-games are built directly on top of `PixelGameProtocol` and rendered at 60 FPS via SwiftUI's hardware-accelerated `Canvas` pipeline:

| Game | Description | Controls & Mechanics |
| :--- | :--- | :--- |
| **🧱 Brick Breaker** | Neon breakout classic with multi-ball and wide paddle power-ups. | D-Pad Left/Right to steer paddle, Button A to launch, dynamic angle reflection physics. |
| **🏎️ Retro Racer** | Top-down high-speed parallax highway racer. | 3-lane quick shift with D-Pad, dynamic oncoming traffic generation, near-miss score bonuses. |
| **🐍 Snake** | Cyber-grid retro snake with progressive tick acceleration. | 4-way D-Pad direction change with anti-reverse lock, glowing oscillating apples, boundary wrapping detection. |
| **🧩 Falling Blocks** | Tetromino puzzle game with 7 pieces, ghost landing guide, and line clears. | D-Pad Left/Right/Down, Button A/B (CW/CCW rotation), Up for instant Hard Drop, SRS wall-kick collision checks. |

---

## 📺 Metal CRT Nostalgia Engine

A dedicated Metal shader (`CRTView.metal`) is applied to the game canvas as a SwiftUI `layerEffect` to reproduce the warmth and artifacts of 1990s Trinitron cathode-ray tubes:

* **Curvature / Barrel Distortion:** Radial UV warping dynamically modulated by hinge angle.
* **Scanlines:** Parametric sinusoidal luminosity modulation matching target DPI.
* **Phosphor Bloom & Glow:** Multi-sample neighbor bloom simulating cathode phosphor persistence.
* **Chromatic Aberration:** Physical RGB channel offset towards screen periphery.
* **Vignetting & Power-On Flash:** Authentic TV tube corner fade and expanding horizontal electron beam animation.

---

## 🕹️ Physical Controls & Skins

The lower screen features an ergonomically calibrated Game Boy style control deck:
* **8-Way Mechanical D-Pad:** Continuous gesture tracking with deadzone rejection.
* **Staggered Action Buttons (A & B):** Angled tactile arrangement with CoreHaptics transient feedback.
* **Start & Select Pills:** Angled rubberized pill buttons for pause and menu access.

### Console Themes & Skins:
1. **Classic Grey:** Nostalgic 1989 off-white and dark grey textured finish.
2. **Atomic Purple:** Translucent frosted casing revealing internal silicon aesthetics.
3. **Cyberpunk Neon:** Pitch-black chassis with glowing cyan accents and hot-pink typography.
4. **Arcade Cabinet:** Woodgrain finish with bright primary arcade buttons.

---

## 💎 StoreKit 2 Monetization

Integrated with modern Swift async/await StoreKit 2:

* **Free Tier:** Instant access to all 4 retro mini-games with Classic Grey chassis.
* **Retro Collector Pack ($6.99):** Unlocks Atomic Purple, Cyberpunk Neon, and Arcade Cabinet skins + custom 8-bit sound packs.
* **Lifetime Pro ($49.99):** Unlocks all current & future games, custom CRT shader fine-tuning, and the upcoming Apple Pencil Cartridge Designer.

---

## 🗂️ Project Directory Structure

```
RetroCartridge/
├── App/
│   ├── RetroCartridgeApp.swift       # @main UIKit entry, orientation-locked SwiftUI host
│   └── AppState.swift                # @Observable central app state & persistent high scores
├── Core/
│   ├── HingeEngine.swift             # Continuous hinge angle pipeline for shaders
│   ├── PostureManager.swift          # Outer / inner display detection
│   ├── HapticManager.swift           # CoreHaptics transient feedback engine
│   └── AudioManager.swift            # 8-bit procedural tone synthesizer (AVAudioEngine)
├── Layout/
│   ├── AdaptiveConsoleLayout.swift   # Root adaptive router (Cover vs FullScreen)
│   ├── CoverScreenLayout.swift       # 5.4" Outer display cartridge selector
│   ├── FullScreenLayout.swift        # 7.6" Inner dual-panel split console
│   ├── FixedOrientation.swift        # Pins each layout to its physical display
│   └── ReservedRegionManager.swift   # Hinge division & occlusion safety manager
├── Rendering/
│   ├── CRTView.metal                 # Stitchable CRT shader (Curvature, Scanline, Bloom, Power-On)
│   └── CRTEffect.swift               # SwiftUI .layerEffect bridge driven by the hinge angle
├── UI/
│   ├── GameCanvasView.swift          # 60 FPS Canvas rendering loop
│   ├── ControllerView.swift          # D-Pad, A/B buttons, and haptic triggers
│   ├── CartridgeInsertView.swift     # Interactive spring physics cartridge drop animation
│   └── Skins/                        # SkinTheme definitions (Classic, Purple, Neon, Arcade)
├── Games/
│   ├── PixelGameProtocol.swift       # Standardized 2D mini-game interface
│   ├── PixelGameEngine.swift         # Game lifecycle & factory engine
│   ├── BrickBreaker/                 # Brick Breaker game implementation
│   ├── RetroRacer/                   # Retro Racer game implementation
│   ├── Snake/                        # Snake game implementation
│   └── FallingBlocks/                # Falling Blocks game implementation
├── Store/
│   ├── StoreManager.swift            # StoreKit 2 transaction observer & product loader
│   └── ProductIdentifiers.swift      # In-App Purchase SKU definitions
└── project.yml                       # Declarative XcodeGen project specification
```

---

## 🚀 Building & Running

### Requirements
- **macOS Sonoma / Sequoia** with Apple Silicon
- **Xcode 27.1+** (with iOS 27.0+ SDK)
- **XcodeGen** (`brew install xcodegen`)
- **Metal Toolchain** (`xcodebuild -downloadComponent MetalToolchain`)

### Quick Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/ErenErgec/iPhone-Duo-RetroCartridge.git
   cd iPhone-Duo-RetroCartridge/RetroCartridge
   ```

2. **Generate the Xcode Project:**
   ```bash
   xcodegen generate
   ```

3. **Open in Xcode:**
   ```bash
   open RetroCartridge.xcodeproj
   ```

4. **Run on iPhone Duo Simulator:**
   - Select the **iPhone Duo** simulator from Xcode's destination dropdown.
   - Press **⌘R** to build and run.
   - Use Xcode’s **Device Hub** (`Features` → `Hinge & Folding State`) to interactively fold, unfold, and tabletop the device to test the adaptive layouts and continuous CRT distortion shaders!

---

## 📄 License
Distributed under the MIT License. See `LICENSE` for more information.

---

Designed with ❤️ for the next generation of dual-screen and foldable devices.
