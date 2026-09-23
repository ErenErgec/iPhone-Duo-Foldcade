//
// GameCanvasView.swift
// RetroCartridge
//
// Rendering canvas for retro games with 60 FPS animation loop.
//

import SwiftUI

struct GameCanvasView: View {
    @Environment(AppState.self) private var appState
    
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
                    .onChange(of: timeline.date) { oldDate, newDate in
                        let delta = newDate.timeIntervalSince(oldDate)
                        activeGame.update(deltaTime: min(max(delta, 0), 0.05))
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
