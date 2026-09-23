// BrickBreakerGame.swift
// RetroCartridge

import SwiftUI

/// Brick Breaker game implementation.
final class BrickBreakerGame: PixelGameProtocol {
    var gameType: GameType = .brickBreaker
    var gameState: GameState = .menu
    var score: Int = 0
    var level: Int = 1
    var highScore: Int = 0
    
    struct Paddle {
        var x: Double = 0.5
        var width: Double = 0.15
        var isWide: Bool = false
        var wideTimeLeft: TimeInterval = 0
    }
    
    struct Ball {
        var x: Double
        var y: Double
        var vx: Double
        var vy: Double
        var history: [(Double, Double)] = []
    }
    
    struct Brick {
        var x: Int
        var y: Int
        var color: Color
        var isDestroyed: Bool = false
    }
    
    struct PowerUp {
        var x: Double
        var y: Double
        var type: PowerUpType
    }
    
    enum PowerUpType {
        case widePaddle
        case multiBall
    }
    
    var paddle: Paddle = Paddle()
    var balls: [Ball] = []
    var bricks: [Brick] = []
    var powerUps: [PowerUp] = []
    
    var lives: Int = 3
    var dpadLeftPressed = false
    var dpadRightPressed = false
    
    let rows = 5
    let cols = 8
    
    init() {
        reset()
    }
    
    func update(deltaTime: TimeInterval) {
        guard gameState == .playing else { return }
        
        // Handle paddle movement
        let paddleSpeed = 0.8 * deltaTime
        if dpadLeftPressed {
            paddle.x -= paddleSpeed
        }
        if dpadRightPressed {
            paddle.x += paddleSpeed
        }
        
        paddle.x = max(paddle.width / 2, min(1.0 - paddle.width / 2, paddle.x))
        
        // Handle paddle powerup expiration
        if paddle.isWide {
            paddle.wideTimeLeft -= deltaTime
            if paddle.wideTimeLeft <= 0 {
                paddle.isWide = false
                paddle.width = 0.15
            }
        }
        
        // Update powerups
        for i in (0..<powerUps.count).reversed() {
            powerUps[i].y += 0.3 * deltaTime
            if powerUps[i].y > 1.0 {
                powerUps.remove(at: i)
                continue
            }
            
            // Check paddle collision
            if powerUps[i].y >= 0.9 && powerUps[i].y <= 0.95 {
                if abs(powerUps[i].x - paddle.x) <= paddle.width / 2 {
                    applyPowerUp(powerUps[i].type)
                    powerUps.remove(at: i)
                }
            }
        }
        
        // Update balls
        for i in (0..<balls.count).reversed() {
            var ball = balls[i]
            
            // Track history
            ball.history.append((ball.x, ball.y))
            if ball.history.count > 3 {
                ball.history.removeFirst()
            }
            
            ball.x += ball.vx * deltaTime
            ball.y += ball.vy * deltaTime
            
            // Wall collisions
            if ball.x <= 0 || ball.x >= 1.0 {
                ball.vx *= -1
                ball.x = ball.x <= 0 ? 0 : 1.0
            }
            if ball.y <= 0 {
                ball.vy *= -1
                ball.y = 0
            }
            
            // Paddle collision
            if ball.y >= 0.9 && ball.y <= 0.92 && ball.vy > 0 {
                if abs(ball.x - paddle.x) <= paddle.width / 2 {
                    ball.vy *= -1
                    // Adjust angle based on hit position
                    let hitFactor = (ball.x - paddle.x) / (paddle.width / 2)
                    ball.vx = hitFactor * 0.8
                    let speed = sqrt(ball.vx * ball.vx + ball.vy * ball.vy)
                    let targetSpeed = 0.6 * pow(1.05, Double(level - 1))
                    ball.vx = (ball.vx / speed) * targetSpeed
                    ball.vy = (ball.vy / speed) * targetSpeed
                }
            }
            
            // Brick collisions
            let brickWidth = 1.0 / Double(cols)
            let brickHeight = 0.05
            let brickStartY = 0.1
            
            for j in 0..<bricks.count {
                if !bricks[j].isDestroyed {
                    let bx = Double(bricks[j].x) * brickWidth
                    let by = brickStartY + Double(bricks[j].y) * brickHeight
                    
                    if ball.x >= bx && ball.x <= bx + brickWidth && ball.y >= by && ball.y <= by + brickHeight {
                        bricks[j].isDestroyed = true
                        score += 10
                        
                        // Spawn powerup?
                        if Double.random(in: 0...1) < 0.20 {
                            powerUps.append(PowerUp(x: bx + brickWidth/2, y: by + brickHeight/2, type: Bool.random() ? .widePaddle : .multiBall))
                        }
                        
                        // Simple collision response
                        if ball.x - ball.vx * deltaTime < bx || ball.x - ball.vx * deltaTime > bx + brickWidth {
                            ball.vx *= -1
                        } else {
                            ball.vy *= -1
                        }
                        break
                    }
                }
            }
            
            // Death check
            if ball.y > 1.0 {
                balls.remove(at: i)
            } else {
                balls[i] = ball
            }
        }
        
        if balls.isEmpty {
            lives -= 1
            if lives <= 0 {
                if score > highScore { highScore = score }
                gameState = .gameOver(score: score)
            } else {
                spawnBall()
            }
        }
        
        // Level completion
        if bricks.allSatisfy({ $0.isDestroyed }) {
            level += 1
            score += 100 * level
            setupLevel()
        }
    }
    
    func applyPowerUp(_ type: PowerUpType) {
        switch type {
        case .widePaddle:
            paddle.isWide = true
            paddle.width = 0.15 * 1.5
            paddle.wideTimeLeft = 10.0
        case .multiBall:
            if let firstBall = balls.first {
                var b1 = firstBall
                b1.vx = -b1.vx
                balls.append(b1)
                
                var b2 = firstBall
                b2.vy = -b2.vy
                balls.append(b2)
            } else {
                spawnBall()
            }
        }
    }
    
    func setupLevel() {
        bricks.removeAll()
        let colors: [Color] = [.red, .orange, .yellow, .green, .cyan]
        for r in 0..<rows {
            for c in 0..<cols {
                bricks.append(Brick(x: c, y: r, color: colors[r % colors.count]))
            }
        }
        balls.removeAll()
        spawnBall()
    }
    
    func spawnBall() {
        let speed = 0.6 * pow(1.05, Double(level - 1))
        balls.append(Ball(x: paddle.x, y: 0.85, vx: speed * 0.707, vy: -speed * 0.707))
    }
    
    func render(context: inout GraphicsContext, size: CGSize) {
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))
        
        if gameState == .menu {
            // Render menu
            return
        }
        
        // Render paddle
        let pWidth = size.width * paddle.width
        let pRect = CGRect(x: size.width * paddle.x - pWidth / 2, y: size.height * 0.9, width: pWidth, height: size.height * 0.02)
        context.fill(Path(pRect), with: .color(.cyan))
        
        // Render bricks
        let brickW = size.width / Double(cols)
        let brickH = size.height * 0.05
        let brickStartY = size.height * 0.1
        
        for brick in bricks where !brick.isDestroyed {
            let rect = CGRect(x: Double(brick.x) * brickW, y: brickStartY + Double(brick.y) * brickH, width: brickW - 2, height: brickH - 2)
            context.fill(Path(rect), with: .color(brick.color))
        }
        
        // Render powerups
        for p in powerUps {
            let rect = CGRect(x: size.width * p.x - 5, y: size.height * p.y - 5, width: 10, height: 10)
            context.fill(Path(rect), with: .color(p.type == .multiBall ? .white : .orange))
        }
        
        // Render balls
        for ball in balls {
            for (idx, pos) in ball.history.enumerated() {
                let rect = CGRect(x: size.width * pos.0 - 2, y: size.height * pos.1 - 2, width: 4, height: 4)
                context.fill(Path(rect), with: .color(.white.opacity(Double(idx + 1) * 0.25)))
            }
            let rect = CGRect(x: size.width * ball.x - 4, y: size.height * ball.y - 4, width: 8, height: 8)
            context.fill(Path(rect), with: .color(.white))
        }
    }
    
    func handleInput(action: GameInputAction) {
        switch action {
        case .dpadLeftPressed: dpadLeftPressed = true
        case .dpadLeftReleased: dpadLeftPressed = false
        case .dpadRightPressed: dpadRightPressed = true
        case .dpadRightReleased: dpadRightPressed = false
        case .buttonAPressed:
            switch gameState {
            case .menu, .gameOver:
                reset()
                gameState = .playing
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
        score = 0
        level = 1
        lives = 3
        paddle = Paddle()
        powerUps.removeAll()
        setupLevel()
    }
}
