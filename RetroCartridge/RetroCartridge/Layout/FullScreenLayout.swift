//
// FullScreenLayout.swift
// RetroCartridge
//

import SwiftUI

public struct FullScreenLayout: View {
    @Environment(AppState.self) private var appState
    @Environment(PostureManager.self) private var postureManager
    
    public init() {}
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(red: 25/255, green: 28/255, blue: 28/255).ignoresSafeArea()
                
                if !appState.isGameActive {
                    // Select a game prompt
                    VStack(spacing: 40) {
                        Text("SELECT A GAME")
                            .font(.largeTitle.monospaced().bold())
                            .foregroundColor(.white)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 30) {
                            ForEach(GameType.allCases, id: \.self) { game in
                                Button {
                                    let engine = PixelGameEngine()
                                    appState.selectedGameType = game
                                    appState.startGame(engine.createGame(type: game))
                                } label: {
                                    VStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(hex: game.cartridgeColorHex))
                                            .frame(height: 100)
                                            .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 5)
                                        Text(game.rawValue)
                                            .font(.headline.monospaced())
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                } else {
                    VStack(spacing: 0) {
                        // Upper Panel - Game Canvas
                        GameCanvasView()
                            .frame(height: geometry.size.height * 0.55)
                            .clipped()
                        
                        // Lower Panel - Controller
                        ControllerView()
                            .frame(height: geometry.size.height * 0.45)
                    }
                }
                
                if appState.isInsertingCartridge {
                    CartridgeInsertView()
                }
            }
        }
    }
}
