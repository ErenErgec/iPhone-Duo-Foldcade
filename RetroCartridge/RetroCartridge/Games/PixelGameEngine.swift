// PixelGameEngine.swift
// RetroCartridge

import SwiftUI
import Observation

/// The main engine managing the active game instance and its lifecycle.
@Observable final class PixelGameEngine {
    
    /// The currently active game.
    public var currentGame: (any PixelGameProtocol)?
    
    /// Indicates whether a game is currently running.
    public var isRunning: Bool = false
    
    public init() {}
    
    /// Creates a game instance based on the provided GameType.
    /// - Parameter type: The type of game to create.
    /// - Returns: A game instance conforming to PixelGameProtocol.
    public func createGame(type: GameType) -> any PixelGameProtocol {
        switch type {
        case .brickBreaker:
            return BrickBreakerGame()
        case .snake:
            return SnakeGame()
        case .retroRacer:
            return RetroRacerGame()
        case .fallingBlocks:
            return FallingBlocksGame()
        }
    }
    
    /// Starts a game of the specified type.
    /// - Parameter type: The type of game to start.
    public func startGame(_ type: GameType) {
        currentGame = createGame(type: type)
        isRunning = true
    }
    
    /// Ends the current game.
    public func endGame() {
        currentGame = nil
        isRunning = false
    }
    
    /// Pauses the current game when device posture changes.
    public func pauseOnPostureChange() {
        currentGame?.pause()
    }
}
