// AppState.swift
// RetroCartridge
//
// Global application state managed with @Observable.
// Tracks active game, selected skin, and UI preferences.

import SwiftUI

@Observable
final class AppState {
    
    // MARK: - Game State
    
    /// The currently selected game type (shown on cover screen carousel).
    var selectedGameType: GameType = .brickBreaker
    
    /// The currently active game instance (nil when on menu/cover screen).
    var activeGame: (any PixelGameProtocol)? = nil
    
    /// Whether a game session is currently in progress.
    var isGameActive: Bool {
        activeGame != nil
    }
    
    // MARK: - Skin & Customization
    
    /// The currently applied console skin.
    var selectedSkin: ConsoleSkinType {
        get {
            let raw = UserDefaults.standard.string(forKey: "selectedSkin") ?? ConsoleSkinType.classicGrey.rawValue
            return ConsoleSkinType(rawValue: raw) ?? .classicGrey
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "selectedSkin")
        }
    }
    
    // MARK: - UI State
    
    /// Whether the cartridge insertion animation is currently playing.
    var isInsertingCartridge: Bool = false
    
    /// Whether the CRT power-on animation has completed.
    var hasPoweredOn: Bool = false
    
    /// Whether the store/shop overlay is visible.
    var isStoreVisible: Bool = false
    
    /// Whether the skin selector is visible.
    var isSkinSelectorVisible: Bool = false
    
    // MARK: - High Scores (Persisted)
    
    /// Get the high score for a specific game type.
    func highScore(for gameType: GameType) -> Int {
        UserDefaults.standard.integer(forKey: "highScore_\(gameType.rawValue)")
    }
    
    /// Update the high score for a specific game type if the new score is higher.
    func updateHighScore(_ score: Int, for gameType: GameType) {
        let current = highScore(for: gameType)
        if score > current {
            UserDefaults.standard.set(score, forKey: "highScore_\(gameType.rawValue)")
        }
    }
    
    // MARK: - Game Lifecycle
    
    /// Start a new game session with the selected game type.
    func startGame(_ game: any PixelGameProtocol) {
        activeGame = game
        isInsertingCartridge = false
        hasPoweredOn = true
    }
    
    /// End the current game session and return to menu.
    func endGame() {
        if let game = activeGame {
            updateHighScore(game.score, for: game.gameType)
        }
        activeGame = nil
        hasPoweredOn = false
    }
    
    /// Pause the active game (e.g., on fold/background).
    func pauseActiveGame() {
        activeGame?.pause()
    }
    
    /// Resume the active game.
    func resumeActiveGame() {
        activeGame?.resume()
    }
}
