//
// AdaptiveConsoleLayout.swift
// RetroCartridge
//
// Root router between the outer (cover) and inner displays.
//
// - Outer display: locked to the landscape orientation with the hinge on top
//   (see `ConsoleHostingController`); a cartridge carousel.
// - Inner display: follows the system's orientation and splits the console at
//   the fold (see `FullScreenLayout`).
//
// App controls (title, Skins, Store) live in the system toolbar, which iPhone
// Duo lays out vertically in the column beside the camera and status bar, or
// as a regular top bar on the inner display in portrait. The toolbar is
// hidden over a running console, an immersive screen without bars
// (DESIGN.md §5–6).
//

import SwiftUI

public struct AdaptiveConsoleLayout: View {
    @Environment(AppState.self) private var appState
    @Environment(PostureManager.self) private var postureManager
    @Environment(HingeEngine.self) private var hingeEngine
    @Environment(AudioManager.self) private var audioManager
    @Environment(HapticManager.self) private var hapticManager

    public init() {}

    public var body: some View {
        ZStack {
            Color(red: 25/255, green: 28/255, blue: 28/255) // #191C1C
                .ignoresSafeArea()

            if postureManager.isCompactWidth {
                ZStack {
                    ConsoleBackdrop(glowColor: Color(hex: appState.selectedGameType.cartridgeColorHex))
                    CoverScreenLayout()
                    LibraryOverlays()
                }
                .transition(.opacity)
            } else {
                FullScreenLayout()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: postureManager.isCompactWidth)
        .navigationTitle("Retro Cartridge")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarItems }
        .toolbarVisibility(showsConsole ? .hidden : .automatic, for: .navigationBar)
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
        // Real hinge angle for the CRT curvature and the unfold chime (visuals only)
        .onHingeChange { _, context in
            hingeEngine.updateFromHardware(context.hinge)
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

    /// A running console on the inner display is immersive: no bars.
    private var showsConsole: Bool {
        !postureManager.isCompactWidth && appState.isGameActive
    }

    // MARK: - Toolbar

    /// Symbol + title items, so the system can lay them out vertically in the
    /// side column (text-only or custom-view items would stay horizontal).
    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                open(\.isSkinSelectorVisible)
            } label: {
                Label("Skins", systemImage: "paintpalette.fill")
            }
            Button {
                open(\.isStoreVisible)
            } label: {
                Label("Store", systemImage: "bag.fill")
            }
        }
    }

    private func open(_ flag: ReferenceWritableKeyPath<AppState, Bool>) {
        audioManager.playCartridgeClick()
        hapticManager.playHaptic(.buttonPress)
        withAnimation(LibraryOverlays.animation) {
            appState[keyPath: flag] = true
        }
    }
}
