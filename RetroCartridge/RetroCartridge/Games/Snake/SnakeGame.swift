// SnakeGame.swift
// RetroCartridge

import SwiftUI

/// Snake game implementation.
final class SnakeGame: PixelGameProtocol {
    var gameType: GameType = .snake
    var gameState: GameState = .menu
    var score: Int = 0
    var level: Int = 1
    var highScore: Int = 0
    var pendingSounds: [GameSound] = []
    
    struct SnakeSegment {
        var x: Int
        var y: Int
    }
    
    enum Direction {
        case up, down, left, right
    }
    
    var snake: [SnakeSegment] = []
    var currentDir: Direction = .right
    var nextDir: Direction = .right
    var food: SnakeSegment = SnakeSegment(x: 10, y: 10)
    
    let gridSize = 20
    var lastMoveTime: TimeInterval = 0
    var moveInterval: TimeInterval = 0.150
    var foodEaten: Int = 0
    
    init() {
        reset()
    }
    
    func update(deltaTime: TimeInterval) {
        guard gameState == .playing else { return }
        
        lastMoveTime += deltaTime
        if lastMoveTime >= moveInterval {
            lastMoveTime = 0
            moveSnake()
        }
    }
    
    func moveSnake() {
        currentDir = nextDir
        var head = snake[0]
        
        switch currentDir {
        case .up: head.y -= 1
        case .down: head.y += 1
        case .left: head.x -= 1
        case .right: head.x += 1
        }
        
        // Wall collision
        if head.x < 0 || head.x >= gridSize || head.y < 0 || head.y >= gridSize {
            die()
            return
        }
        
        // Self collision
        if snake.contains(where: { $0.x == head.x && $0.y == head.y }) {
            die()
            return
        }
        
        snake.insert(head, at: 0)
        
        // Food collision
        if head.x == food.x && head.y == food.y {
            score += 10 * level
            foodEaten += 1
            emit(.eat)
            if foodEaten % 5 == 0 {
                level += 1
                emit(.levelUp)
                moveInterval = max(0.060, moveInterval - 0.005)
            }
            spawnFood()
        } else {
            snake.removeLast()
        }
    }
    
    func spawnFood() {
        var placed = false
        while !placed {
            let fx = Int.random(in: 0..<gridSize)
            let fy = Int.random(in: 0..<gridSize)
            if !snake.contains(where: { $0.x == fx && $0.y == fy }) {
                food = SnakeSegment(x: fx, y: fy)
                placed = true
            }
        }
    }
    
    func die() {
        if score > highScore { highScore = score }
        gameState = .gameOver(score: score)
        emit(.collision)
        emit(.gameOver)
    }
    
    func render(context: inout GraphicsContext, size: CGSize) {
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))
        
        if gameState == .menu { return }
        
        // Square cells, board centered on the screen
        let cellSize = min(size.width, size.height) / Double(gridSize)
        let cellW = cellSize
        let cellH = cellSize
        let boardX = (size.width - cellSize * Double(gridSize)) / 2
        let boardY = (size.height - cellSize * Double(gridSize)) / 2
        context.translateBy(x: boardX, y: boardY)
        
        // Grid
        for i in 0...gridSize {
            var path = Path()
            path.move(to: CGPoint(x: Double(i) * cellW, y: 0))
            path.addLine(to: CGPoint(x: Double(i) * cellW, y: cellH * Double(gridSize)))
            context.stroke(path, with: .color(Color(white: 0.1)), lineWidth: 1)
            
            var path2 = Path()
            path2.move(to: CGPoint(x: 0, y: Double(i) * cellH))
            path2.addLine(to: CGPoint(x: cellW * Double(gridSize), y: Double(i) * cellH))
            context.stroke(path2, with: .color(Color(white: 0.1)), lineWidth: 1)
        }
        
        // Food
        let pulse = (sin(Date().timeIntervalSince1970 * 5) + 1) / 2
        let foodRect = CGRect(x: Double(food.x) * cellW + 2, y: Double(food.y) * cellH + 2, width: cellW - 4, height: cellH - 4)
        context.fill(Path(foodRect), with: .color(Color(hex: "00FF41").opacity(0.5 + pulse * 0.5)))
        
        // Snake
        for (i, seg) in snake.enumerated() {
            let rect = CGRect(x: Double(seg.x) * cellW + 1, y: Double(seg.y) * cellH + 1, width: cellW - 2, height: cellH - 2)
            context.fill(Path(rect), with: .color(i == 0 ? Color(hex: "50FF80") : Color(hex: "00FF41")))
        }
    }
    
    func handleInput(action: GameInputAction) {
        switch action {
        case .dpadUpPressed: if currentDir != .down { nextDir = .up }
        case .dpadDownPressed: if currentDir != .up { nextDir = .down }
        case .dpadLeftPressed: if currentDir != .right { nextDir = .left }
        case .dpadRightPressed: if currentDir != .left { nextDir = .right }
        case .buttonAPressed:
            switch gameState {
            case .menu, .gameOver:
                reset()
                gameState = .playing
                emit(.roundStart)
            default: break
            }
        case .buttonStartPressed:
            if gameState == .playing { pause() }
            else if gameState == .paused { resume() }
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
        snake = [
            SnakeSegment(x: 10, y: 10),
            SnakeSegment(x: 9, y: 10),
            SnakeSegment(x: 8, y: 10)
        ]
        currentDir = .right
        nextDir = .right
        moveInterval = 0.150
        foodEaten = 0
        spawnFood()
    }
}

