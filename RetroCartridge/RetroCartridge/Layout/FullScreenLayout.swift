//
// FullScreenLayout.swift
// RetroCartridge
//
// 7.6" inner display. Without a game it shows the cartridge library; with a
// game it becomes a clamshell handheld split exactly at the hinge: the CRT on
// the upper half and the control deck on the lower half. The display is
// locked to portrait (see AdaptiveConsoleLayout), so this layout never rotates.
//

import SwiftUI

public struct FullScreenLayout: View {
    @Environment(AppState.self) private var appState
    @Environment(HapticManager.self) private var hapticManager
    @Environment(AudioManager.self) private var audioManager
    @Environment(\.fixedSafeAreaInsets) private var insets

    public init() {}

    public var body: some View {
        ZStack {
            if appState.isGameActive {
                console
                    .transition(.opacity)
            } else {
                library
                    .transition(.opacity)
            }

            if appState.isInsertingCartridge {
                CartridgeInsertView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isGameActive)
    }

    // MARK: - Console

    private var console: some View {
        let theme = SkinManager.theme(for: appState.selectedSkin)
        
        return GeometryReader { geo in
            let half = geo.size.height / 2
            
            ZStack {
                ConsoleShell(theme: theme)
                
                // Halves are measured on the full display so the split lands on the hinge.
                VStack(spacing: 0) {
                    GameCanvasView()
                        .padding(.top, insets.top)
                        .padding(.leading, insets.leading)
                        .padding(.trailing, insets.trailing)
                        .frame(width: geo.size.width, height: half)
                    
                    ControllerView()
                        .padding(.bottom, insets.bottom)
                        .padding(.leading, insets.leading)
                        .padding(.trailing, insets.trailing)
                        .frame(width: geo.size.width, height: half)
                }
                
                HingeGroove()
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Library

    private var library: some View {
        VStack(spacing: 36) {
            VStack(spacing: 10) {
                Text("RETRO CARTRIDGE")
                    .font(.system(size: 34, weight: .black, design: .monospaced))
                    .tracking(4)
                    .foregroundStyle(.white)
                Text("CHOOSE A CARTRIDGE")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .tracking(4)
                    .foregroundStyle(.white.opacity(0.45))
            }

            // One row of four when it fits, otherwise a balanced 2×2 grid
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 28) {
                    ForEach(GameType.allCases) { cartridgeButton($0) }
                }
                Grid(horizontalSpacing: 28, verticalSpacing: 28) {
                    GridRow {
                        cartridgeButton(.brickBreaker)
                        cartridgeButton(.retroRacer)
                    }
                    GridRow {
                        cartridgeButton(.snake)
                        cartridgeButton(.fallingBlocks)
                    }
                }
            }
        }
        .padding(32)
        .padding(insets)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ConsoleBackdrop(glowColor: Color(hex: appState.selectedGameType.cartridgeColorHex)))
    }
    
    private func cartridgeButton(_ game: GameType) -> some View {
        Button {
            audioManager.playCartridgeClick()
            hapticManager.playHaptic(.cartridgeInsert)
            appState.startGame(type: game)
        } label: {
            VStack(spacing: 12) {
                CartridgeView(
                    game: game,
                    highScore: appState.highScore(for: game),
                    isSelected: game == appState.selectedGameType
                )
                Text(game.subtitle)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: 170)
        }
        .buttonStyle(CartridgePressStyle())
    }
}

// MARK: - Shell

/// The molded plastic body of the console in the current skin.
private struct ConsoleShell: View {
    let theme: SkinTheme

    var body: some View {
        ZStack {
            Color.black
            theme.bodyColor
            LinearGradient(
                colors: [.white.opacity(0.14), .clear, .black.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
}

/// A subtle groove marking where the device folds.
private struct HingeGroove: View {
    var body: some View {
        Rectangle()
            .fill(LinearGradient(colors: [.black.opacity(0.25), .white.opacity(0.12)], startPoint: .top, endPoint: .bottom))
            .frame(height: 2)
            .frame(maxWidth: .infinity)
    }
}
