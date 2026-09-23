//
// CoverScreenLayout.swift
// RetroCartridge
//
// 5.4" outer display: a swipeable cartridge case. The device is held closed
// with the hinge on top, so this display is landscape (see AdaptiveConsoleLayout).
// The chosen cartridge is inserted automatically when the device is unfolded.
//

import SwiftUI

public struct CoverScreenLayout: View {
    @Environment(AppState.self) private var appState
    @State private var blink: Bool = false

    public init() {}

    public var body: some View {
        GeometryReader { geo in
            // Hinge-on-top pose: cartridge on the left, details on the right
            HStack(spacing: 0) {
                carousel(cartridgeWidth: min(geo.size.height * 0.72 * CartridgeView.aspectRatio, geo.size.width * 0.4))
                    .frame(width: geo.size.width * 0.48)
                
                VStack(alignment: .leading, spacing: 0) {
                    wordmark
                    Spacer()
                    details(alignment: .leading)
                    pageIndicator
                        .padding(.top, 16)
                    Spacer()
                    unfoldPrompt
                }
                .padding(.vertical, 24)
                .padding(.trailing, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    // MARK: - Pieces

    private var wordmark: some View {
        Text("RETRO CARTRIDGE")
            .font(.system(size: 13, weight: .heavy, design: .monospaced))
            .tracking(4)
            .foregroundStyle(.white.opacity(0.55))
    }

    private func carousel(cartridgeWidth: CGFloat) -> some View {
        @Bindable var appState = appState

        return TabView(selection: $appState.selectedGameType) {
            ForEach(GameType.allCases) { game in
                CartridgeView(
                    game: game,
                    highScore: appState.highScore(for: game),
                    isSelected: game == appState.selectedGameType
                )
                .frame(width: cartridgeWidth)
                .padding(.vertical, 20)
                .tag(game)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private func details(alignment: HorizontalAlignment) -> some View {
        let selected = appState.selectedGameType

        return VStack(alignment: alignment, spacing: 8) {
            Text(selected.rawValue.uppercased())
                .font(.system(size: 24, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(selected.subtitle)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))

            let best = appState.highScore(for: selected)
            if best > 0 {
                Text("HI \(best)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: selected.cartridgeColorHex))
                    .padding(.top, 2)
            }
        }
        .contentTransition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: selected)
    }

    private var pageIndicator: some View {
        let selected = appState.selectedGameType

        return HStack(spacing: 8) {
            ForEach(GameType.allCases) { game in
                Capsule()
                    .fill(game == selected ? Color(hex: game.cartridgeColorHex) : Color.white.opacity(0.2))
                    .frame(width: game == selected ? 22 : 7, height: 7)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selected)
    }

    private var unfoldPrompt: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.up.and.down")
                .font(.system(size: 14, weight: .bold))
            Text("UNFOLD TO PLAY")
                .font(.system(size: 15, weight: .heavy, design: .monospaced))
                .tracking(3)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.06))
                .overlay(Capsule().stroke(Color(hex: appState.selectedGameType.cartridgeColorHex).opacity(0.6), lineWidth: 1))
        )
        .opacity(blink ? 1.0 : 0.35)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: blink)
        .onAppear { blink = true }
    }
}
