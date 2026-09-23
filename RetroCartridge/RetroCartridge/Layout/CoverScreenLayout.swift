//
// CoverScreenLayout.swift
// RetroCartridge
//

import SwiftUI

public struct CoverScreenLayout: View {
    @Environment(AppState.self) private var appState
    @State private var blink: Bool = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Retro Cartridge Slot Visualization
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.15))
                    .frame(width: 160, height: 100)
                    .shadow(color: .black.opacity(0.8), radius: 5, x: 0, y: 5)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(white: 0.1))
                    .frame(width: 140, height: 20)
                
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(white: 0.25), lineWidth: 2)
                    .frame(width: 140, height: 20)
            }
            
            Text(appState.selectedGameType.rawValue)
                .font(.title2.monospaced().bold())
                .foregroundColor(.white)
            
            // Carousel for game selection
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(GameType.allCases, id: \.self) { game in
                        Button {
                            appState.selectedGameType = game
                        } label: {
                            VStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(hex: game.cartridgeColorHex))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(appState.selectedGameType == game ? Color.white : Color.clear, lineWidth: 2)
                                    )
                                Text(game.rawValue)
                                    .font(.caption.monospaced())
                                    .foregroundColor(appState.selectedGameType == game ? .white : .gray)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 100)
            
            Spacer()
            
            Text("UNFOLD TO PLAY")
                .font(.headline.monospaced())
                .foregroundColor(.white)
                .opacity(blink ? 1.0 : 0.2)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: blink)
                .onAppear {
                    blink = true
                }
            
            Spacer()
        }
        .background(Color(red: 25/255, green: 28/255, blue: 28/255).ignoresSafeArea())
    }
}
