// GameModels.swift
// RetroCartridge
//
// Shared types used across all modules.

import Foundation

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
    case dpadRelease
    
    // Action buttons (press)
    case buttonAPressed
    case buttonBPressed
    
    // Action button release
    case buttonAReleased
    case buttonBReleased
    
    // System buttons
    case buttonStartPressed
    case buttonSelectPressed
    
    // MARK: - Convenience aliases used by ControllerView
    
    static var up: GameInputAction { .dpadUpPressed }
    static var down: GameInputAction { .dpadDownPressed }
    static var left: GameInputAction { .dpadLeftPressed }
    static var right: GameInputAction { .dpadRightPressed }
    static var a: GameInputAction { .buttonAPressed }
    static var b: GameInputAction { .buttonBPressed }
    static var start: GameInputAction { .buttonStartPressed }
    static var select: GameInputAction { .buttonSelectPressed }
}

// MARK: - Device Posture

/// Represents the physical posture of the iPhone Duo.
/// Used by PostureManager for layout decisions.
/// Note: Layout decisions use Size Classes, NOT hinge angle (per Apple HIG).
enum DevicePosture: Equatable, CustomStringConvertible {
    case closed
    case halfOpened
    case fullyOpen
    
    var description: String {
        switch self {
        case .closed: return "Closed"
        case .halfOpened: return "Half-Opened (Tabletop)"
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

// MARK: - Game Type

/// Identifies each available mini-game.
enum GameType: String, CaseIterable, Identifiable, Codable {
    case brickBreaker = "Brick Breaker"
    case retroRacer = "Retro Racer"
    case snake = "Snake"
    case fallingBlocks = "Falling Blocks"
    
    var id: String { rawValue }
    
    /// Short description for the game selection UI.
    var subtitle: String {
        switch self {
        case .brickBreaker: return "Classic paddle & ball action"
        case .retroRacer: return "8-bit highway dodge"
        case .snake: return "Neon grid serpent"
        case .fallingBlocks: return "Block stacking puzzle"
        }
    }
    
    /// SF Symbol artwork printed on the cartridge label.
    var symbolName: String {
        switch self {
        case .brickBreaker: return "square.grid.3x2.fill"
        case .retroRacer: return "car.fill"
        case .snake: return "scribble.variable"
        case .fallingBlocks: return "square.stack.3d.down.right.fill"
        }
    }
    
    /// Cartridge label color for the cover screen carousel.
    var cartridgeColorHex: String {
        switch self {
        case .brickBreaker: return "#FF6B6B"
        case .retroRacer: return "#4ECDC4"
        case .snake: return "#45B7D1"
        case .fallingBlocks: return "#F7DC6F"
        }
    }
}

// MARK: - Haptic Event Type

/// Identifies haptic feedback patterns for different interactions.
enum HapticEventType {
    case buttonPress          // D-Pad & action buttons
    case buttonRelease        // Button release feedback
    case cartridgeInsert      // Cartridge slot-in moment
    case hingeClick           // Hinge close mechanical click
    case gameEvent            // In-game collision, line clear, etc.
}
