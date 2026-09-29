// GamePalette.swift
// RetroCartridge
//
// The colors a game draws with, named by their role on screen. Games never
// hard-code colors in `render`; they read their `palette`, so the same game
// can be shown in another palette without touching its code. Each game's own
// palette lives next to it (e.g. `GamePalette.snake` in SnakeGame.swift).

import SwiftUI

// MARK: - Game Palette

/// Colors a game renders with, by role.
struct GamePalette: Equatable, Sendable {
    /// Clears the screen every frame.
    var background: Color

    /// Faint guides over the background: grid lines, lane markings.
    var guide: Color

    /// The player's piece: paddle, car, snake body.
    var player: Color

    /// An emphasised player detail: the snake's head, the ball.
    var playerHighlight: Color

    /// Something good to collect: food, a power-up.
    var pickup: Color

    /// A second kind of pickup, told apart from the first.
    var pickupAlt: Color

    /// Something to avoid: traffic.
    var hazard: Color

    /// A second kind of hazard, told apart from the first.
    var hazardAlt: Color

    /// Edges drawn around solid cells.
    var outline: Color

    /// Ordered colors for families of objects, such as brick rows or block
    /// shapes. Read them with `spectrumColor(_:)`, which wraps around.
    var spectrum: [Color]

    /// The spectrum color at `index`, wrapping around in both directions.
    func spectrumColor(_ index: Int) -> Color {
        guard !spectrum.isEmpty else { return player }
        let count = spectrum.count
        return spectrum[((index % count) + count) % count]
    }

    /// The palette a game was designed with.
    static func native(for game: GameType) -> GamePalette {
        switch game {
        case .brickBreaker: return .brickBreaker
        case .retroRacer: return .retroRacer
        case .snake: return .snake
        case .fallingBlocks: return .fallingBlocks
        }
    }
}
