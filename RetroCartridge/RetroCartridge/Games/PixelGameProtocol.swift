// PixelGameProtocol.swift
// RetroCartridge
//
// Common protocol for all retro mini-games.
// Each game conforms to this protocol and is managed by PixelGameEngine.

import SwiftUI

// MARK: - Pixel Game Protocol

/// The contract every mini-game must fulfill to integrate with the game engine.
///
/// The engine calls `update(deltaTime:)` every frame (~60 FPS),
/// then `render(context:size:)` to draw the current state.
/// Input is forwarded from the controller via `handleInput(action:)`.
protocol PixelGameProtocol: AnyObject {
    
    /// The type of this game, used for identification and UI display.
    var gameType: GameType { get }
    
    /// The current state of the game (menu, playing, paused, gameOver).
    var gameState: GameState { get set }
    
    /// The player's current score.
    var score: Int { get }
    
    /// The current level/difficulty.
    var level: Int { get }
    
    /// High score for this game (persisted).
    var highScore: Int { get set }

    // MARK: - Sound

    /// Sound effects raised since the last frame. Games add to it with
    /// `emit(_:)`; the frame loop empties it with `drainSounds()` and plays
    /// them, so games never depend on the audio system.
    var pendingSounds: [GameSound] { get set }

    // MARK: - Game Loop
    
    /// Called every frame by the game engine.
    /// - Parameter deltaTime: Time elapsed since the last frame, in seconds.
    func update(deltaTime: TimeInterval)
    
    /// Called every frame after `update` to render the current game state.
    /// - Parameters:
    ///   - context: The SwiftUI GraphicsContext for drawing.
    ///   - size: The available canvas size.
    func render(context: inout GraphicsContext, size: CGSize)
    
    // MARK: - Input
    
    /// Called when the player interacts with the controller.
    /// - Parameter action: The input action from D-Pad or buttons.
    func handleInput(action: GameInputAction)
    
    // MARK: - Lifecycle
    
    /// Pause the game (e.g., when device folds or app backgrounds).
    func pause()
    
    /// Resume the game from a paused state.
    func resume()
    
    /// Reset the game to its initial state for a fresh start.
    func reset()
}

// MARK: - Default Implementations

extension PixelGameProtocol {
    
    func pause() {
        if case .playing = gameState {
            gameState = .paused
        }
    }
    
    func resume() {
        if case .paused = gameState {
            gameState = .playing
        }
    }

    /// Queues a sound effect for the next frame. Duplicates within a frame
    /// are dropped (e.g. several bricks breaking at once play one sound).
    func emit(_ sound: GameSound) {
        guard !pendingSounds.contains(sound), pendingSounds.count < 8 else { return }
        pendingSounds.append(sound)
    }

    /// Returns and clears the queued sound effects.
    func drainSounds() -> [GameSound] {
        guard !pendingSounds.isEmpty else { return [] }
        let sounds = pendingSounds
        pendingSounds = []
        return sounds
    }
}

// MARK: - Grid Helpers

/// A position on the pixel game grid.
struct GridPosition: Equatable, Hashable {
    var x: Int
    var y: Int
    
    static func + (lhs: GridPosition, rhs: GridPosition) -> GridPosition {
        GridPosition(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
}

/// A floating-point position for smooth movement in pixel games.
struct GameVector: Equatable {
    var x: CGFloat
    var y: CGFloat
    
    static let zero = GameVector(x: 0, y: 0)
    
    static func + (lhs: GameVector, rhs: GameVector) -> GameVector {
        GameVector(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func * (lhs: GameVector, rhs: CGFloat) -> GameVector {
        GameVector(x: lhs.x * rhs, y: lhs.y * rhs)
    }
}
