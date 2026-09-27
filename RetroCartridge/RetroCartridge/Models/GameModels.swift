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
