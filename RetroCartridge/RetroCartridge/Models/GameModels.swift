// GameModels.swift
// RetroCartridge
//
// Shared types used across all modules.

import SwiftUI

// MARK: - Game State

/// Represents the current state of any mini-game.
enum GameState: Equatable {
    case menu
    case playing
    case paused
    case gameOver(score: Int)
}

// MARK: - Game Input

/// All possible controller input actions from the D-Pad and buttons.
enum GameInputAction: Equatable {
    // D-Pad directions (press)
    case dpadUpPressed
    case dpadDownPressed
    case dpadLeftPressed
    case dpadRightPressed
    
    // D-Pad release
    case dpadLeftReleased
    case dpadRightReleased
    case dpadUpReleased
    case dpadDownReleased
    
    // Action buttons (press)
    case buttonAPressed
    case buttonBPressed
    
    // Action button release
    case buttonAReleased
    case buttonBReleased
    
    // System buttons
    case buttonStartPressed
    case buttonSelectPressed
}

// MARK: - Device Posture

/// Represents the physical posture of the iPhone Duo, derived by
/// PostureManager from which display the app is on (never from the hinge angle).
enum DevicePosture: Equatable, CustomStringConvertible {
    case closed
    case fullyOpen
    
    var description: String {
        switch self {
        case .closed: return "Closed"
        case .fullyOpen: return "Fully Open"
        }
    }
}

// MARK: - Console Skin

/// Available console skin themes.
enum ConsoleSkinType: String, CaseIterable, Identifiable, Codable {
    case classicGrey = "Classic Grey"
    case atomicPurple = "Atomic Purple"
    case cyberpunkNeon = "Cyberpunk Neon"
    case arcadeCabinet = "90's Arcade Cabinet"
    
    var id: String { rawValue }
    
    /// Whether this skin is available in the free tier.
    var isFree: Bool {
        switch self {
        case .classicGrey: return true
        default: return false
        }
    }
    
    /// The IAP product ID required to unlock this skin (nil if free).
    var requiredProductID: String? {
        isFree ? nil : ProductIdentifiers.retroCollectorPack
    }
}

// MARK: - Game Mode

/// A rule set a cartridge can be played with. Each mode keeps its own high
/// score. Every game supports `.standard`, the rules it shipped with.
struct GameMode: Hashable, Identifiable, Sendable {
    /// Stable identifier, used in persistence keys. Never rename a shipped one.
    let id: String

    /// Short name for menus, e.g. "SPRINT".
    let title: String

    /// One-line summary of the rules.
    let summary: String

    static let standard = GameMode(id: "standard", title: "Standard", summary: "The classic rules.")
}

// MARK: - Cartridge

/// The molded plastic a cartridge shell is made of.
struct CartridgeShell: Equatable, Sendable {
    /// Top of the shell's vertical gradient.
    var topColor: Color

    /// Bottom of the shell's vertical gradient.
    var bottomColor: Color

    /// See-through plastic, drawn by the cartridge artwork.
    var isTranslucent: Bool = false

    /// The standard grey shell.
    static let grey = CartridgeShell(topColor: Color(white: 0.36), bottomColor: Color(white: 0.24))
}

/// Everything the library, cover and store know about a cartridge, kept in
/// one place so a new game is described by a single `GameType.info` case.
struct CartridgeInfo: Sendable {
    /// Short description for the game selection UI.
    let subtitle: String

    /// Genre printed on the cartridge, e.g. "PUZZLE".
    let genre: String

    /// SF Symbol artwork printed on the cartridge label.
    let symbolName: String

    /// Cartridge label color, also used to tint the backdrop.
    let labelColorHex: String

    /// The plastic of the cartridge shell.
    var shell: CartridgeShell = .grey

    /// The rule sets the game offers. The first one is the default.
    var modes: [GameMode] = [.standard]

    /// The IAP product that unlocks the cartridge, nil when it is free.
    var requiredProductID: String? = nil
}

// MARK: - Game Type

/// Identifies each available mini-game.
enum GameType: String, CaseIterable, Identifiable, Codable {
    case brickBreaker = "Brick Breaker"
    case retroRacer = "Retro Racer"
    case snake = "Snake"
    case fallingBlocks = "Falling Blocks"
    
    var id: String { rawValue }

    /// The cartridge's metadata.
    var info: CartridgeInfo {
        switch self {
        case .brickBreaker:
            return CartridgeInfo(
                subtitle: "Classic paddle & ball action",
                genre: "ARCADE",
                symbolName: "square.grid.3x2.fill",
                labelColorHex: "#FF6B6B"
            )
        case .retroRacer:
            return CartridgeInfo(
                subtitle: "8-bit highway dodge",
                genre: "RACING",
                symbolName: "car.fill",
                labelColorHex: "#4ECDC4"
            )
        case .snake:
            return CartridgeInfo(
                subtitle: "Neon grid serpent",
                genre: "ACTION",
                symbolName: "scribble.variable",
                labelColorHex: "#45B7D1"
            )
        case .fallingBlocks:
            return CartridgeInfo(
                subtitle: "Block stacking puzzle",
                genre: "PUZZLE",
                symbolName: "square.stack.3d.down.right.fill",
                labelColorHex: "#F7DC6F"
            )
        }
    }

    // MARK: Shorthands

    /// Short description for the game selection UI.
    var subtitle: String { info.subtitle }

    /// Genre printed on the cartridge.
    var genre: String { info.genre }

    /// SF Symbol artwork printed on the cartridge label.
    var symbolName: String { info.symbolName }

    /// Cartridge label color for the cover screen carousel.
    var cartridgeColorHex: String { info.labelColorHex }

    /// The rule sets the game offers. The first one is the default.
    var modes: [GameMode] { info.modes }

    /// Whether the cartridge is playable without a purchase.
    var isFree: Bool { info.requiredProductID == nil }
}

// MARK: - Haptic Event Type

/// Identifies haptic feedback patterns for different interactions.
enum HapticEventType {
    case buttonPress          // D-Pad & action buttons
    case cartridgeInsert      // Cartridge slot-in moment
    case hingeClick           // Hinge close mechanical click
    case gameEvent            // In-game collision, line clear, etc.
}

// MARK: - Game Sound

/// Sound effects a game can raise. Games queue these with
/// `PixelGameProtocol.emit(_:)`; the frame loop plays them through `AudioManager`.
enum GameSound: Equatable, Sendable {
    // Shared
    case roundStart
    case levelUp
    case gameOver
    case powerUp
    case collision

    // Brick Breaker
    case paddleBounce
    case wallBounce
    case brickBreak
    case lifeLost

    // Snake
    case eat

    // Retro Racer
    case laneChange
    case crash

    // Falling Blocks
    case moveTick
    case rotate
    case pieceLock
    case hardDrop
    case lineClear(lines: Int)

    /// Whether the event is big enough to also fire the `.gameEvent` haptic.
    var isImpactful: Bool {
        switch self {
        case .collision, .crash, .lifeLost, .lineClear, .gameOver:
            return true
        default:
            return false
        }
    }
}
