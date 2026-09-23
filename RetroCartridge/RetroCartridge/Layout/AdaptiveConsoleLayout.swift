//
// AdaptiveConsoleLayout.swift
// RetroCartridge
//
// Root router between the outer (cover) and inner displays.
//
// The console has one fixed pose: held closed with the hinge on top, and
// opened like a clamshell. The app is locked to the system's portrait
// orientation on both displays (Info.plist), so iOS never rotates it or plays
// a rotation animation when the device folds. Each layout is drawn to match
// that pose:
// - Outer display: turned 90° counter-clockwise, giving a landscape layout
//   with the hinge on top.
// - Inner display: the locked portrait already puts the hinge horizontally
//   across the middle, with the CRT above it and the controller below.
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
                    FixedOrientation(turn: .counterClockwise) {
                        CoverScreenLayout()
                    }
                }
                .transition(.opacity)
            } else {
                FullScreenLayout()
                    .transition(.opacity)
            }
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
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

/// Lays content out for a display turned a quarter turn from the (locked)
/// interface orientation and rotates it into place. Safe area insets are
/// remapped to the turned edges, since the rotation itself is render-only.
private struct FixedOrientation<Content: View>: View {
    enum Turn {
        /// Content's top edge lies along the display's left edge.
        case counterClockwise
    }

    let turn: Turn
    @ViewBuilder var content: Content

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let insets = geo.safeAreaInsets

            switch turn {
            case .counterClockwise:
                content
                    .ignoresSafeArea()
                    .padding(EdgeInsets(
                        top: insets.leading,
                        leading: insets.bottom,
                        bottom: insets.trailing,
                        trailing: insets.top
                    ))
                    .frame(width: size.height, height: size.width)
                    .rotationEffect(.degrees(-90))
                    .frame(width: size.width, height: size.height)
            }
        }
        .ignoresSafeArea()
    }
}
