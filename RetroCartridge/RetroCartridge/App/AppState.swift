// AppState.swift
// RetroCartridge
//
// Global application state managed with @Observable.
// Tracks active game, selected skin, UI preferences and player progress.

import SwiftUI

@Observable
final class AppState {

    /// High scores and achievements, persisted.
    let progress: ProgressStore

    init(progress: ProgressStore = ProgressStore()) {
        self.progress = progress
    }
    
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
    
    /// Whether the store overlay is visible (drawn in-hierarchy by the library,
    /// never as a sheet, so it follows the pinned display orientation).
    var isStoreVisible: Bool = false

    /// Whether the skin picker overlay is visible. The store stacks above it.
    var isSkinSelectorVisible: Bool = false
    
    // MARK: - High Scores (Persisted)
    
    /// The high score for a game type in a mode.
    func highScore(for gameType: GameType, mode: GameMode = .standard) -> Int {
        progress.highScore(for: gameType, mode: mode)
    }
    
    /// Update the high score for a game type in a mode if the new score is higher.
    func updateHighScore(_ score: Int, for gameType: GameType, mode: GameMode = .standard) {
        progress.recordScore(score, for: gameType, mode: mode)
    }
    
    // MARK: - Game Lifecycle
    
    /// Insert a cartridge: create a fresh game of the given type and power on.
    func startGame(type: GameType, mode: GameMode = .standard) {
        selectedGameType = type
        startGame(PixelGameEngine.createGame(type: type, mode: mode))
    }
    
    /// Start a new game session with the selected game type.
    func startGame(_ game: any PixelGameProtocol) {
        activeGame = game
        // Library overlays shouldn't reappear when the cartridge is ejected.
        isStoreVisible = false
        isSkinSelectorVisible = false
    }
    
    /// End the current game session and return to menu.
    func endGame() {
        if let game = activeGame {
            updateHighScore(game.score, for: game.gameType, mode: game.mode)
        }
        activeGame = nil
    }
    
    /// Pause the active game (e.g., on fold/background).
    func pauseActiveGame() {
        activeGame?.pause()
    }
}
