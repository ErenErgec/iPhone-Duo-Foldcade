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

            // Skin picker and store are in-hierarchy overlays, never sheets:
            // sheets would follow the scene's locked orientation instead of
            // this display's counter-rotated one (see FixedOrientation).
            if showsSkinPicker {
                OverlayBackdrop { closeOverlay(\.isSkinSelectorVisible) }
                    .transition(.opacity)
                    .zIndex(10)
                SkinPickerView()
                    .transition(.overlayPanel)
                    .zIndex(11)
            }

            if showsStore {
                OverlayBackdrop { closeOverlay(\.isStoreVisible) }
                    .transition(.opacity)
                    .zIndex(12)
                StoreView()
                    .transition(.overlayPanel)
                    .zIndex(13)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isGameActive)
        .animation(Self.overlayAnimation, value: showsSkinPicker)
        .animation(Self.overlayAnimation, value: showsStore)
    }

    // MARK: - Overlays

    private static let overlayAnimation = Animation.spring(response: 0.38, dampingFraction: 0.86)

    /// Overlays belong to the library, so they never cover a running console.
    private var showsSkinPicker: Bool {
        appState.isSkinSelectorVisible && !appState.isGameActive
    }

    private var showsStore: Bool {
        appState.isStoreVisible && !appState.isGameActive
    }

    private func openOverlay(_ flag: ReferenceWritableKeyPath<AppState, Bool>) {
        audioManager.playCartridgeClick()
        hapticManager.playHaptic(.buttonPress)
        withAnimation(Self.overlayAnimation) {
            appState[keyPath: flag] = true
        }
    }

    private func closeOverlay(_ flag: ReferenceWritableKeyPath<AppState, Bool>) {
        withAnimation(Self.overlayAnimation) {
            appState[keyPath: flag] = false
        }
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
        ZStack(alignment: .top) {
            libraryContent
                .padding(32)
                .padding(insets)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            libraryHeader
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.top, insets.top)
                .padding(.leading, insets.leading)
                .padding(.trailing, insets.trailing)
        }
        .background(ConsoleBackdrop(glowColor: Color(hex: appState.selectedGameType.cartridgeColorHex)))
    }

    /// Top bar with the Skins and Store entry points.
    private var libraryHeader: some View {
        HStack(spacing: 10) {
            Spacer(minLength: 0)

            Button {
                openOverlay(\.isSkinSelectorVisible)
            } label: {
                LibraryHeaderLabel(title: "SKINS", systemImage: "paintpalette.fill") {
                    Circle()
                        .fill(SkinManager.theme(for: appState.selectedSkin).bodyColor)
                        .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1))
                        .frame(width: 10, height: 10)
                }
            }
            .buttonStyle(CartridgePressStyle())
            .accessibilityLabel("Skins")
            .accessibilityValue(appState.selectedSkin.rawValue)

            Button {
                openOverlay(\.isStoreVisible)
            } label: {
                LibraryHeaderLabel(title: "STORE", systemImage: "bag.fill") {
                    EmptyView()
                }
            }
            .buttonStyle(CartridgePressStyle())
            .accessibilityLabel("Store")
        }
    }

    private var libraryContent: some View {
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

// MARK: - Library header

/// Capsule button label for the library's top bar.
private struct LibraryHeaderLabel<Badge: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let badge: Badge

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(RetroPalette.phosphor)
            Text(title)
                .font(.system(size: 13, weight: .heavy, design: .monospaced))
                .tracking(3)
                .foregroundStyle(.white.opacity(0.85))
            badge
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Capsule().fill(Color.white.opacity(0.06)))
        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
        .contentShape(Capsule())
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
