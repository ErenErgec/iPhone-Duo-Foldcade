//
// FullScreenLayout.swift
// RetroCartridge
//
// 7.6" inner display. Without a game it shows the cartridge library; with a
// game it becomes a handheld console split exactly at the fold, using the
// fold's reserved region: CRT above and controls below in portrait (the
// clamshell / laptop pose), CRT on the leading side in landscape (book pose).
// The inner display doesn't honor orientation locks, so the layout adapts to
// whatever orientation the system uses (DESIGN.md §4).
//

import SwiftUI

public struct FullScreenLayout: View {
    @Environment(AppState.self) private var appState
    @Environment(HapticManager.self) private var hapticManager
    @Environment(AudioManager.self) private var audioManager

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

            // Overlays belong to the library, so they never cover a running console.
            LibraryOverlays(isEnabled: !appState.isGameActive)
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isGameActive)
    }
    
    // MARK: - Console

    private var console: some View {
        let theme = SkinManager.theme(for: appState.selectedSkin)
        
        return GeometryReader { geo in
            let split = FoldSplit(
                size: geo.size,
                fold: geo.reservedRegions(kind: .division, options: .includeInactive).first?.frame
            )
            let insets = geo.safeAreaInsets
            
            ZStack(alignment: .topLeading) {
                ConsoleShell(theme: theme)
                
                // Halves are measured on the full display so the split lands on
                // the fold; each half then keeps clear of its own screen edges.
                GameCanvasView()
                    .padding(split.firstHalfInsets(from: insets))
                    .frame(width: split.first.width, height: split.first.height)
                    .offset(x: split.first.minX, y: split.first.minY)
                
                ControllerView()
                    .padding(split.secondHalfInsets(from: insets))
                    .frame(width: split.second.width, height: split.second.height)
                    .offset(x: split.second.minX, y: split.second.minY)
                
                HingeGroove(isVertical: split.isSideBySide)
                    .frame(
                        width: split.isSideBySide ? 2 : geo.size.width,
                        height: split.isSideBySide ? geo.size.height : 2
                    )
                    .offset(
                        x: split.isSideBySide ? split.foldPosition - 1 : 0,
                        y: split.isSideBySide ? 0 : split.foldPosition - 1
                    )
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Library

    private var library: some View {
        libraryContent
            .padding(32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ConsoleBackdrop(glowColor: Color(hex: appState.selectedGameType.cartridgeColorHex)))
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
    let isVertical: Bool
    
    var body: some View {
        Rectangle().fill(
            LinearGradient(
                colors: [.black.opacity(0.25), .white.opacity(0.12)],
                startPoint: isVertical ? .leading : .top,
                endPoint: isVertical ? .trailing : .bottom
            )
        )
    }
}

// MARK: - Fold split

/// Splits the display into two halves at the fold. The fold comes from the
/// `.division` reserved region, queried with `.includeInactive` so it is
/// known even when the device is flat; without one, the display is split in
/// the middle across its longer side.
struct FoldSplit {
    /// The CRT half: top in portrait, leading in landscape.
    let first: CGRect
    /// The controller half: bottom in portrait, trailing in landscape.
    let second: CGRect
    /// True when the fold runs vertically, so the halves sit side by side.
    let isSideBySide: Bool
    /// The fold's center along the split axis.
    let foldPosition: CGFloat
    
    init(size: CGSize, fold: CGRect?) {
        if let fold, fold.width != fold.height {
            isSideBySide = fold.height > fold.width
        } else {
            isSideBySide = size.width > size.height
        }
        
        if isSideBySide {
            let center = fold.map { $0.midX } ?? size.width / 2
            let halfGap = (fold?.width ?? 0) / 2
            foldPosition = center
            first = CGRect(x: 0, y: 0, width: center - halfGap, height: size.height)
            second = CGRect(x: center + halfGap, y: 0, width: size.width - center - halfGap, height: size.height)
        } else {
            let center = fold.map { $0.midY } ?? size.height / 2
            let halfGap = (fold?.height ?? 0) / 2
            foldPosition = center
            first = CGRect(x: 0, y: 0, width: size.width, height: center - halfGap)
            second = CGRect(x: 0, y: center + halfGap, width: size.width, height: size.height - center - halfGap)
        }
    }
    
    /// Safe area insets on the first half's outer edges.
    func firstHalfInsets(from insets: EdgeInsets) -> EdgeInsets {
        isSideBySide
            ? EdgeInsets(top: insets.top, leading: insets.leading, bottom: insets.bottom, trailing: 0)
            : EdgeInsets(top: insets.top, leading: insets.leading, bottom: 0, trailing: insets.trailing)
    }
    
    /// Safe area insets on the second half's outer edges.
    func secondHalfInsets(from insets: EdgeInsets) -> EdgeInsets {
        isSideBySide
            ? EdgeInsets(top: insets.top, leading: 0, bottom: insets.bottom, trailing: insets.trailing)
            : EdgeInsets(top: 0, leading: insets.leading, bottom: insets.bottom, trailing: insets.trailing)
    }
}
