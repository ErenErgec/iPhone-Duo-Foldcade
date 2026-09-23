//
// GameCanvasView.swift
// RetroCartridge
//
// Rendering canvas for retro games with 60 FPS animation loop.
//

import SwiftUI

struct GameCanvasView: View {
    @Environment(AppState.self) private var appState
    @Environment(HingeEngine.self) private var hingeEngine
    
    /// When the CRT power-on animation started. This view is created fresh
    /// for each game session, so every cartridge gets its own power-on.
    @State private var powerOnStart = Date()
    
    /// Duration of the CRT power-on animation, in seconds.
    private let powerOnDuration: TimeInterval = 0.9
    
    init() {}
    
    var body: some View {
        ZStack {
            // Dark background with CRT-like border
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black, lineWidth: 4)
                        .shadow(color: .white.opacity(0.1), radius: 2, x: 0, y: 0)
                )
                .padding(8)
            
            if let activeGame = appState.activeGame {
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        activeGame.render(context: &context, size: size)
                    }
                    .crtEffect(
                        hingeAngle: hingeEngine.hingeAngle,
                        powerOnProgress: timeline.date.timeIntervalSince(powerOnStart) / powerOnDuration
                    )
                    .onChange(of: timeline.date) { oldDate, newDate in
                        let delta = newDate.timeIntervalSince(oldDate)
                        activeGame.update(deltaTime: min(max(delta, 0), 0.05))

                        // Persist the score as soon as a round ends, since pressing A
                        // restarts the game and resets its score.
                        if case .gameOver(let score) = activeGame.gameState {
                            appState.updateHighScore(score, for: activeGame.gameType)
                        }
                    }
                }
                .padding(16)
            } else {
                // Retro "INSERT CARTRIDGE" text with scanlines
                ZStack {
                    VStack(spacing: 2) {
                        ForEach(0..<100) { _ in
                            Rectangle()
                                .fill(Color.black.opacity(0.2))
                                .frame(height: 1)
                        }
                    }
                    
                    Text("INSERT CARTRIDGE")
                        .font(.title.monospaced().bold())
                        .foregroundColor(.green)
                        .shadow(color: .green, radius: 2, x: 0, y: 0)
                }
                .padding(16)
            }
        }
        .background(Color.black)
    }
}
