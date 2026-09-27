// FallingBlocksGame.swift
// RetroCartridge

import SwiftUI

/// Falling Blocks (Tetris-style) game implementation.
final class FallingBlocksGame: PixelGameProtocol {
    var gameType: GameType = .fallingBlocks
    var gameState: GameState = .menu
    var score: Int = 0
    var level: Int = 1
    var highScore: Int = 0
    var pendingSounds: [GameSound] = []
    
    let cols = 10
    let rows = 20
    
    var grid: [[Color?]] = Array(repeating: Array(repeating: nil, count: 10), count: 20)
    
    struct Tetromino {
        var shape: [[Int]]
        var color: Color
        var x: Int
        var y: Int
        
        mutating func rotateClockwise() {
            let s = shape.count
            var newShape = Array(repeating: Array(repeating: 0, count: s), count: s)
            for i in 0..<s {
                for j in 0..<s {
                    newShape[j][s - 1 - i] = shape[i][j]
                }
            }
            shape = newShape
        }
        
        mutating func rotateCounterClockwise() {
            let s = shape.count
            var newShape = Array(repeating: Array(repeating: 0, count: s), count: s)
            for i in 0..<s {
                for j in 0..<s {
                    newShape[s - 1 - j][i] = shape[i][j]
                }
            }
            shape = newShape
        }
    }
    
    let pieceTypes: [([[Int]], Color)] = [
        ([[0,0,0,0], [1,1,1,1], [0,0,0,0], [0,0,0,0]], .cyan), // I
        ([[1,1], [1,1]], .yellow), // O
        ([[0,1,0], [1,1,1], [0,0,0]], .purple), // T
        ([[0,1,1], [1,1,0], [0,0,0]], .green), // S
        ([[1,1,0], [0,1,1], [0,0,0]], .red), // Z
        ([[0,0,1], [1,1,1], [0,0,0]], .orange), // L
        ([[1,0,0], [1,1,1], [0,0,0]], .blue) // J
    ]
    
    var currentPiece: Tetromino!
    var nextPiece: Tetromino!
    
    var dropTimer: TimeInterval = 0
    var dropInterval: TimeInterval = 0.8
    var linesClearedTotal = 0
    
    init() {
        reset()
    }
    
    func spawnPiece() {
        if nextPiece == nil {
            let type = pieceTypes.randomElement()!
            nextPiece = Tetromino(shape: type.0, color: type.1, x: cols/2 - type.0.count/2, y: 0)
        }
        currentPiece = nextPiece
        let type = pieceTypes.randomElement()!
        nextPiece = Tetromino(shape: type.0, color: type.1, x: cols/2 - type.0.count/2, y: 0)
        
        if checkCollision(piece: currentPiece, dx: 0, dy: 0) {
            die()
        }
    }
    
    func update(deltaTime: TimeInterval) {
        guard gameState == .playing else { return }
        
        dropTimer += deltaTime
        if dropTimer >= dropInterval {
            dropTimer = 0
            if !checkCollision(piece: currentPiece, dx: 0, dy: 1) {
                currentPiece.y += 1
            } else {
                lockPiece()
            }
        }
    }
    
    /// Merges the current piece into the grid, clears lines and spawns the next piece.
    /// - Parameter sound: The landing sound; a hard drop plays its own slam.
    func lockPiece(sound: GameSound = .pieceLock) {
        emit(sound)
        for i in 0..<currentPiece.shape.count {
            for j in 0..<currentPiece.shape[i].count {
                if currentPiece.shape[i][j] == 1 {
                    let r = currentPiece.y + i
                    let c = currentPiece.x + j
                    if r >= 0 && r < rows && c >= 0 && c < cols {
                        grid[r][c] = currentPiece.color
                    }
                }
            }
        }
        
        clearLines()
        spawnPiece()
    }
    
    func clearLines() {
        var linesCleared = 0
        for r in (0..<rows).reversed() {
            if grid[r].allSatisfy({ $0 != nil }) {
                grid.remove(at: r)
                grid.insert(Array(repeating: nil, count: cols), at: 0)
                linesCleared += 1
            }
        }
        
        if linesCleared > 0 {
            linesClearedTotal += linesCleared
            emit(.lineClear(lines: linesCleared))
            let newLevel = 1 + linesClearedTotal / 10
            if newLevel > level {
                emit(.levelUp)
            }
            level = newLevel
            dropInterval = max(0.1, 0.8 - Double(level - 1) * 0.05)
            
            switch linesCleared {
            case 1: score += 100 * level
            case 2: score += 300 * level
            case 3: score += 500 * level
            case 4: score += 800 * level
            default: break
            }
        }
    }
    
    func checkCollision(piece: Tetromino, dx: Int, dy: Int) -> Bool {
        for i in 0..<piece.shape.count {
            for j in 0..<piece.shape[i].count {
                if piece.shape[i][j] == 1 {
                    let r = piece.y + i + dy
                    let c = piece.x + j + dx
                    
                    if c < 0 || c >= cols || r >= rows { return true }
                    if r >= 0 && grid[r][c] != nil { return true }
                }
            }
        }
        return false
    }
    
    func getGhostPiece() -> Tetromino {
        var ghost = currentPiece!
        while !checkCollision(piece: ghost, dx: 0, dy: 1) {
            ghost.y += 1
        }
        return ghost
    }
    
    func die() {
        if score > highScore { highScore = score }
        gameState = .gameOver(score: score)
        emit(.gameOver)
    }
    
    func render(context: inout GraphicsContext, size: CGSize) {
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))
        
        if gameState == .menu { return }
        
        let cellW = size.width / Double(cols)
        let cellH = size.height / Double(rows)
        let cellSize = min(cellW, cellH)
        
        let offsetX = (size.width - Double(cols) * cellSize) / 2
        let offsetY = (size.height - Double(rows) * cellSize) / 2
        
        // Draw grid
        for r in 0..<rows {
            for c in 0..<cols {
                let rect = CGRect(x: offsetX + Double(c) * cellSize, y: offsetY + Double(r) * cellSize, width: cellSize, height: cellSize)
                if let color = grid[r][c] {
                    context.fill(Path(rect), with: .color(color))
                    context.stroke(Path(rect), with: .color(.black), lineWidth: 1)
                }
            }
        }
        
        guard currentPiece != nil else { return }
        
        // Ghost piece
        let ghost = getGhostPiece()
        for i in 0..<ghost.shape.count {
            for j in 0..<ghost.shape[i].count {
                if ghost.shape[i][j] == 1 {
                    let rect = CGRect(x: offsetX + Double(ghost.x + j) * cellSize, y: offsetY + Double(ghost.y + i) * cellSize, width: cellSize, height: cellSize)
                    context.stroke(Path(rect), with: .color(ghost.color.opacity(0.5)), lineWidth: 2)
                }
            }
        }
        
        // Current piece
        for i in 0..<currentPiece.shape.count {
            for j in 0..<currentPiece.shape[i].count {
                if currentPiece.shape[i][j] == 1 {
                    let rect = CGRect(x: offsetX + Double(currentPiece.x + j) * cellSize, y: offsetY + Double(currentPiece.y + i) * cellSize, width: cellSize, height: cellSize)
                    context.fill(Path(rect), with: .color(currentPiece.color))
                    context.stroke(Path(rect), with: .color(.black), lineWidth: 1)
                }
            }
        }
    }
    
    func handleInput(action: GameInputAction) {
        guard gameState == .playing else {
            if action == .buttonStartPressed {
                resume()
                return
            }
            if action == .buttonAPressed {
                switch gameState {
                case .menu, .gameOver:
                    reset()
                    gameState = .playing
                    emit(.roundStart)
                default: break
                }
            }
            return
        }
        
        switch action {
        case .dpadLeftPressed:
            if !checkCollision(piece: currentPiece, dx: -1, dy: 0) {
                currentPiece.x -= 1
                emit(.moveTick)
            }
        case .dpadRightPressed:
            if !checkCollision(piece: currentPiece, dx: 1, dy: 0) {
                currentPiece.x += 1
                emit(.moveTick)
            }
        case .dpadDownPressed:
            if !checkCollision(piece: currentPiece, dx: 0, dy: 1) {
                currentPiece.y += 1
                score += 1
            }
        case .dpadUpPressed:
            while !checkCollision(piece: currentPiece, dx: 0, dy: 1) {
                currentPiece.y += 1
                score += 2
            }
            lockPiece(sound: .hardDrop)
        case .buttonAPressed:
            var temp = currentPiece!
            temp.rotateClockwise()
            if !checkCollision(piece: temp, dx: 0, dy: 0) {
                currentPiece = temp
                emit(.rotate)
            }
        case .buttonBPressed:
            var temp = currentPiece!
            temp.rotateCounterClockwise()
            if !checkCollision(piece: temp, dx: 0, dy: 0) {
                currentPiece = temp
                emit(.rotate)
            }
        case .buttonStartPressed:
            pause()
        default: break
        }
    }
    
    func pause() {
        if gameState == .playing { gameState = .paused }
    }
    
    func resume() {
        if gameState == .paused { gameState = .playing }
    }
    
    func reset() {
        gameState = .menu
        pendingSounds.removeAll()
        score = 0
        level = 1
        linesClearedTotal = 0
        dropInterval = 0.8
        grid = Array(repeating: Array(repeating: nil, count: 10), count: 20)
        currentPiece = nil
        nextPiece = nil
        spawnPiece()
    }
}
