//
// AdaptiveConsoleLayout.swift
// RetroCartridge
//
// Root router between the outer (cover) and inner displays.
//
// The console has one fixed pose: held closed with the hinge on top, and
// opened like a clamshell. Each display's layout is pinned to the physical
// panel with `FixedOrientation`, so it never rotates:
// - Outer display: landscape with the hinge on top.
// - Inner display: portrait, with the hinge running horizontally across the
//   middle — CRT above it, controller below.
//

import SwiftUI

public struct AdaptiveConsoleLayout: View {
    @Environment(AppState.self) private var appState
    @Environment(PostureManager.self) private var postureManager

    public init() {}

    public var body: some View {
        ZStack {
            Color(red: 25/255, green: 28/255, blue: 28/255) // #191C1C
                .ignoresSafeArea()

            if postureManager.isCompactWidth {
                ZStack {
                    ConsoleBackdrop(glowColor: Color(hex: appState.selectedGameType.cartridgeColorHex))
                    FixedOrientation(design: .landscapeLeft) {
                        CoverScreenLayout()
                    }
                }
                .transition(.opacity)
            } else {
                FixedOrientation(design: .portrait, padsSafeArea: false, ignoresHalfTurns: true) {
                    FullScreenLayout()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: postureManager.isCompactWidth)
        .background {
            // Measure the whole display (not the safe area) to tell which one we're on
            Color.clear
                .onGeometryChange(for: CGSize.self) { proxy in
                    proxy.size
                } action: { size in
                    postureManager.updateDisplay(fullScreenSize: size)
                }
                .ignoresSafeArea()
        }
        .onChange(of: postureManager.isCompactWidth) { wasCompact, isCompact in
            if wasCompact && !isCompact && !appState.isGameActive {
                // Unfolded: insert the cartridge chosen on the cover screen
                appState.startGame(type: appState.selectedGameType)
            } else if isCompact {
                // Folded: keep the session but pause it (app continuity)
                appState.pauseActiveGame()
            }
        }
    }
}
