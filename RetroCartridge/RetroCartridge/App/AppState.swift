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
    
    /// The currently applied console skin. A stored property so `@Observable`
    /// tracks it and every view reading it refreshes; persisted on change.
    var selectedSkin: ConsoleSkinType = AppState.persistedSkin() {
        didSet {
            guard selectedSkin != oldValue else { return }
            UserDefaults.standard.set(selectedSkin.rawValue, forKey: Self.selectedSkinKey)
        }
    }

    private static let selectedSkinKey = "selectedSkin"

    private static func persistedSkin() -> ConsoleSkinType {
        UserDefaults.standard.string(forKey: selectedSkinKey)
            .flatMap(ConsoleSkinType.init(rawValue:)) ?? .classicGrey
    }
    
    // MARK: - UI State
    
    /// Whether the cartridge insertion animation is currently playing.
    var isInsertingCartridge: Bool = false
    
    /// Whether the CRT power-on animation has completed.
    var hasPoweredOn: Bool = false
    
    /// Whether the store overlay is visible (drawn in-hierarchy by the library,
    /// never as a sheet, so it follows the pinned display orientation).
    var isStoreVisible: Bool = false

    /// Whether the skin picker overlay is visible. The store stacks above it.
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
    
    /// Insert a cartridge: create a fresh game of the given type and power on.
    func startGame(type: GameType) {
        selectedGameType = type
        startGame(PixelGameEngine().createGame(type: type))
    }
    
    /// Start a new game session with the selected game type.
    func startGame(_ game: any PixelGameProtocol) {
        activeGame = game
        isInsertingCartridge = false
        // Library overlays shouldn't reappear when the cartridge is ejected.
        isStoreVisible = false
        isSkinSelectorVisible = false
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
