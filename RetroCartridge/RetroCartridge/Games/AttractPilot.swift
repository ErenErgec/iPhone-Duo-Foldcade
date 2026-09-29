// AttractPilot.swift
// RetroCartridge
//
// Plays a game by itself for the cover screen's attract mode, the way
// arcade cabinets demo themselves. The pilot only reads game state and
// sends the same inputs a player would, so games need no demo code. It
// plays well but not perfectly, and starts a new round after a game over.

import Foundation

final class AttractPilot {

    /// The game being played.
    let game: any PixelGameProtocol

    /// Time since the pilot started, for its deliberate imperfections.
    private var clock: TimeInterval = 0

    /// Time spent on the game-over screen before starting again.
    private var gameOverTime: TimeInterval = 0

    /// D-Pad directions currently held down.
    private var held: Set<Hold> = []

    private enum Hold {
        case left, right
    }

    // Falling Blocks plan for the current piece
    private var lastPieceY = Int.max
    private var targetColumn = 0
    private var rotationsLeft = 0
    private var moveTimer: TimeInterval = 0

    init(type: GameType) {
        game = PixelGameEngine.createGame(type: type)
        game.handleInput(action: .buttonAPressed)
    }

    // MARK: - Frame

    /// Decides this frame's inputs, then advances the game. Sounds are
    /// dropped: attract mode is silent.
    func step(deltaTime: TimeInterval) {
        clock += deltaTime

        switch game.gameState {
        case .gameOver:
            release()
            gameOverTime += deltaTime
            if gameOverTime > 1.5 {
                gameOverTime = 0
                game.handleInput(action: .buttonAPressed)
            }
        case .menu, .paused:
            game.handleInput(action: .buttonAPressed)
            game.resume()
        case .playing:
            steer(deltaTime: deltaTime)
        }

        game.update(deltaTime: deltaTime)
        _ = game.drainSounds()
    }

    private func steer(deltaTime: TimeInterval) {
        switch game {
        case let brickBreaker as BrickBreakerGame:
            steer(brickBreaker)
        case let snake as SnakeGame:
            steer(snake)
        case let racer as RetroRacerGame:
            steer(racer)
        case let blocks as FallingBlocksGame:
            steer(blocks, deltaTime: deltaTime)
        default:
            break
        }
    }

    // MARK: - Held directions

    /// Holds left, right or neither, sending presses and releases only on change.
    private func hold(_ direction: Hold?) {
        for current in held where current != direction {
            game.handleInput(action: current == .left ? .dpadLeftReleased : .dpadRightReleased)
            held.remove(current)
        }
        if let direction, !held.contains(direction) {
            game.handleInput(action: direction == .left ? .dpadLeftPressed : .dpadRightPressed)
            held.insert(direction)
        }
    }

    private func release() {
        hold(nil)
    }

    // MARK: - Brick Breaker

    /// Follows the lowest falling ball, with a slowly wandering aim error
    /// so the paddle misses now and then.
    private func steer(_ game: BrickBreakerGame) {
        let falling = game.balls.filter { $0.vy > 0 }
        guard let ball = falling.max(by: { $0.y < $1.y }) ?? game.balls.first else {
            release()
            return
        }
        let aimError = sin(clock * 0.7) * 0.07
        let target = ball.x + aimError
        if game.paddle.x < target - 0.02 {
            hold(.right)
        } else if game.paddle.x > target + 0.02 {
            hold(.left)
        } else {
            release()
        }
    }

    // MARK: - Snake

    /// Heads for the food along whichever safe direction gets closest.
    private func steer(_ game: SnakeGame) {
        guard let head = game.snake.first else { return }

        let options: [(SnakeGame.Direction, GameInputAction, Int, Int)] = [
            (.up, .dpadUpPressed, 0, -1),
            (.down, .dpadDownPressed, 0, 1),
            (.left, .dpadLeftPressed, -1, 0),
            (.right, .dpadRightPressed, 1, 0)
        ]

        var best: (action: GameInputAction, distance: Int)?
        for (direction, action, dx, dy) in options {
            guard !isReverse(direction, of: game.currentDir) else { continue }
            var x = head.x + dx
            var y = head.y + dy
            if game.wrapsAround {
                x = (x + game.gridSize) % game.gridSize
                y = (y + game.gridSize) % game.gridSize
            }
            let cell = SnakeGame.SnakeSegment(x: x, y: y)
            let isSafe = x >= 0 && x < game.gridSize && y >= 0 && y < game.gridSize
                && !game.obstacles.contains(cell)
                && !game.snake.dropLast().contains(cell)
            guard isSafe else { continue }
            let distance = abs(game.food.x - x) + abs(game.food.y - y)
            if best == nil || distance < best!.distance {
                best = (action, distance)
            }
        }

        if let best {
            game.handleInput(action: best.action)
        }
    }

    private func isReverse(_ direction: SnakeGame.Direction, of current: SnakeGame.Direction) -> Bool {
        switch (direction, current) {
        case (.up, .down), (.down, .up), (.left, .right), (.right, .left):
            return true
        default:
            return false
        }
    }

    // MARK: - Retro Racer

    /// Changes lanes away from traffic that is getting close.
    private func steer(_ game: RetroRacerGame) {
        func isBlocked(_ lane: Int) -> Bool {
            game.obstacles.contains { $0.lane == lane && $0.y > 0.3 && $0.y < 0.95 }
        }
        guard isBlocked(game.targetLane) else { return }

        let lanes = [game.targetLane - 1, game.targetLane + 1].filter { (0...2).contains($0) }
        if let free = lanes.first(where: { !isBlocked($0) }) {
            game.handleInput(action: free < game.targetLane ? .dpadLeftPressed : .dpadRightPressed)
        }
    }

    // MARK: - Falling Blocks

    /// Picks a rotation and column for each new piece, walks it there a step
    /// at a time and drops it.
    private func steer(_ game: FallingBlocksGame, deltaTime: TimeInterval) {
        guard let piece = game.currentPiece else { return }

        // A new piece spawns higher than the last one was
        if piece.y < lastPieceY {
            rotationsLeft = Int.random(in: 0...3)
            targetColumn = Int.random(in: 0...(game.cols - piece.shape.count))
        }
        lastPieceY = piece.y

        moveTimer += deltaTime
        guard moveTimer >= 0.12 else { return }
        moveTimer = 0

        if rotationsLeft > 0 {
            rotationsLeft -= 1
            game.handleInput(action: .buttonAPressed)
        } else if piece.x < targetColumn {
            let before = piece.x
            game.handleInput(action: .dpadRightPressed)
            if game.currentPiece?.x == before { targetColumn = before }
        } else if piece.x > targetColumn {
            let before = piece.x
            game.handleInput(action: .dpadLeftPressed)
            if game.currentPiece?.x == before { targetColumn = before }
        } else {
            game.handleInput(action: .dpadUpPressed)
            lastPieceY = Int.max
        }
    }
}
