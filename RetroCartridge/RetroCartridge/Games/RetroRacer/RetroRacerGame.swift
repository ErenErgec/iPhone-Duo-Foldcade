// RetroRacerGame.swift
// RetroCartridge

import SwiftUI

/// Retro Racer game implementation.
final class RetroRacerGame: PixelGameProtocol {
    var gameType: GameType = .retroRacer
    var gameState: GameState = .menu
    var score: Int = 0
    var level: Int = 1
    var highScore: Int = 0
    var pendingSounds: [GameSound] = []
    
    struct Car {
        var lane: Int
        var y: Double
        var color: Color
    }
    
    var playerLane: Double = 1.0 // 0, 1, 2
    var targetLane: Int = 1
    var obstacles: [Car] = []
    
    var roadOffset: Double = 0
    var speed: Double = 0.5
    var spawnTimer: TimeInterval = 0
    var currentSpawnInterval: TimeInterval = 1.5
    
    var survivalTime: TimeInterval = 0
    
    init() {
        reset()
    }
    
    func update(deltaTime: TimeInterval) {
        guard gameState == .playing else { return }
        
        // One point per second survived, independent of frame rate
        survivalTime += deltaTime
        while survivalTime >= 1.0 {
            survivalTime -= 1.0
            score += 1
        }
        
        // Level up over time
        let newLevel = 1 + score / 100
        if newLevel > level {
            emit(.levelUp)
        }
        level = newLevel
        speed = 0.5 + Double(level) * 0.05
        currentSpawnInterval = max(0.4, 1.5 - Double(level - 1) * 0.1)
        
        // Player lane interpolation
        let laneDiff = Double(targetLane) - playerLane
        playerLane += laneDiff * min(1.0, 10.0 * deltaTime)
        
        // Road scrolling
        roadOffset += speed * deltaTime
        if roadOffset > 1.0 { roadOffset -= 1.0 }
        
        // Spawn obstacles
        spawnTimer -= deltaTime
        if spawnTimer <= 0 {
            spawnTimer = currentSpawnInterval
            let lane = Int.random(in: 0...2)
            let color = Bool.random() ? Color(hex: "E63946") : Color(hex: "FFD166")
            obstacles.append(Car(lane: lane, y: -0.2, color: color))
        }
        
        // Update obstacles
        let playerRect = CGRect(x: playerLane * 0.33 + 0.165 - 0.05, y: 0.8, width: 0.1, height: 0.1)
        
        for i in (0..<obstacles.count).reversed() {
            obstacles[i].y += speed * deltaTime
            
            let obsRect = CGRect(x: Double(obstacles[i].lane) * 0.33 + 0.165 - 0.05, y: obstacles[i].y, width: 0.1, height: 0.1)
            
            // Collision
            if playerRect.intersects(obsRect) {
                die()
                return
            }
            
            // Near miss logic could be added here
            
            if obstacles[i].y > 1.2 {
                obstacles.remove(at: i)
            }
        }
    }
    
    func die() {
        if score > highScore { highScore = score }
        gameState = .gameOver(score: score)
        emit(.crash)
        emit(.gameOver)
    }
    
    func render(context: inout GraphicsContext, size: CGSize) {
        // Road
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: "1a1a2e")))
        
        if gameState == .menu { return }
        
        // Road lines
        for i in 1...2 {
            var path = Path()
            path.move(to: CGPoint(x: size.width * (Double(i) * 0.333), y: 0))
            path.addLine(to: CGPoint(x: size.width * (Double(i) * 0.333), y: size.height))
            // Basic dashed lines with offset
            context.stroke(path, with: .color(.white.opacity(0.3)), style: StrokeStyle(lineWidth: 2, dash: [20, 20], dashPhase: CGFloat(-roadOffset * Double(size.height))))
        }
        
        // Obstacles
        for obs in obstacles {
            let cx = size.width * (Double(obs.lane) * 0.333 + 0.166)
            let cy = size.height * obs.y
            let rect = CGRect(x: cx - 20, y: cy - 30, width: 40, height: 60)
            context.fill(Path(rect), with: .color(obs.color))
        }
        
        // Player
        let px = size.width * (playerLane * 0.333 + 0.166)
        let py = size.height * 0.85
        let pRect = CGRect(x: px - 20, y: py - 30, width: 40, height: 60)
        context.fill(Path(pRect), with: .color(Color(hex: "4361EE")))
    }
    
    func handleInput(action: GameInputAction) {
        switch action {
        case .dpadLeftPressed:
            if targetLane > 0 {
                targetLane -= 1
                if gameState == .playing { emit(.laneChange) }
            }
        case .dpadRightPressed:
            if targetLane < 2 {
                targetLane += 1
                if gameState == .playing { emit(.laneChange) }
            }
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
        playerLane = 1.0
        targetLane = 1
        obstacles.removeAll()
        survivalTime = 0
        roadOffset = 0
    }
}
