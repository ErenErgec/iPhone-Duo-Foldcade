//
// CartridgeInsertView.swift
// RetroCartridge
//

import SwiftUI

public struct CartridgeInsertView: View {
    @Environment(AppState.self) private var appState
    @Environment(HapticManager.self) private var hapticManager
    @Environment(AudioManager.self) private var audioManager
    
    @State private var offset: CGFloat = -400
    @State private var isInserted: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Dark overlay background
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            // The cartridge
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: appState.selectedGameType.cartridgeColorHex))
                .frame(width: 200, height: 150)
                .shadow(color: .black.opacity(0.6), radius: 10, x: 0, y: 10)
                .overlay(
                    VStack {
                        Spacer()
                        Text(appState.selectedGameType.rawValue)
                            .font(.title2.monospaced().bold())
                            .foregroundColor(.white)
                            .padding(.bottom, 30)
                    }
                )
                .offset(y: offset)
                .onAppear {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.1)) {
                        offset = 0
                    }
                    
                    // Completion
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        isInserted = true
                        audioManager.playCartridgeClick()
                        hapticManager.playHaptic(.cartridgeInsert)
                        appState.isInsertingCartridge = false
                    }
                }
        }
    }
}
