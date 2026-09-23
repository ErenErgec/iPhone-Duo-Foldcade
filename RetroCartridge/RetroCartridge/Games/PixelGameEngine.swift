// PixelGameEngine.swift
// RetroCartridge

/// Creates game instances for each cartridge.
enum PixelGameEngine {
    
    /// Creates a fresh game of the given type.
    static func createGame(type: GameType) -> any PixelGameProtocol {
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
}
