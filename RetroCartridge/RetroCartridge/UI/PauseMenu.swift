//
// PauseMenu.swift
// RetroCartridge
//
// The on-screen display shown inside the tube while a game is paused, like
// a TV's settings menu. The controller drives it (D-Pad moves and changes,
// A selects, B resumes, Start still resumes through the game), so games
// stay unaware of it. It sits in the CRT, next to the content it affects.
//

import SwiftUI

// MARK: - Items

/// A row of the pause menu.
enum PauseMenuItem: Int, CaseIterable, Sendable {
    case resume
    case screen
    case eject

    var title: String {
        switch self {
        case .resume: return "RESUME"
        case .screen: return "SCREEN"
        case .eject: return "EJECT"
        }
    }
}

// MARK: - Input

enum PauseMenu {

    /// What pressing a button in the pause menu did, for feedback.
    enum Outcome {
        case moved
        case changed
        case confirmed
        case ignored
    }

    /// Screen modes the player can switch between from the menu.
    @MainActor
    static func availableScreenModes(store: StoreManager) -> [ScreenMode] {
        ScreenMode.allCases.filter { store.isUnlocked($0) }
    }

    /// Applies a controller press to the pause menu.
    /// - Parameters:
    ///   - screenModes: The modes the player may switch between.
    ///   - currentScreen: The mode being drawn now.
    @discardableResult
    static func handle(
        _ action: GameInputAction,
        appState: AppState,
        screenModes: [ScreenMode],
        currentScreen: ScreenMode
    ) -> Outcome {
        let items = PauseMenuItem.allCases
        let selection = appState.pauseMenuSelection

        switch action {
        case .dpadUpPressed, .dpadDownPressed:
            let step = action == .dpadUpPressed ? -1 : 1
            let index = (selection.rawValue + step + items.count) % items.count
            appState.pauseMenuSelection = items[index]
            return .moved

        case .dpadLeftPressed, .dpadRightPressed:
            guard selection == .screen else { return .ignored }
            return cycleScreen(by: action == .dpadLeftPressed ? -1 : 1, appState: appState, modes: screenModes, current: currentScreen)

        case .buttonAPressed:
            switch selection {
            case .resume:
                resume(appState)
                return .confirmed
            case .screen:
                return cycleScreen(by: 1, appState: appState, modes: screenModes, current: currentScreen)
            case .eject:
                appState.ejectCartridge()
                return .confirmed
            }

        case .buttonBPressed:
            resume(appState)
            return .confirmed

        default:
            return .ignored
        }
    }

    private static func resume(_ appState: AppState) {
        appState.pauseMenuSelection = .resume
        appState.activeGame?.resume()
    }

    private static func cycleScreen(by step: Int, appState: AppState, modes: [ScreenMode], current: ScreenMode) -> Outcome {
        guard modes.count > 1 else { return .ignored }
        let index = modes.firstIndex(of: current) ?? 0
        appState.screenSettings.mode = modes[(index + step + modes.count) % modes.count]
        return .changed
    }
}

// MARK: - On-screen display

/// The pause menu as drawn inside the tube, in the phosphor style of the
/// other in-tube messages.
struct PauseMenuPanel: View {
    let selection: PauseMenuItem
    let screenModeTitle: String
    let canChangeScreen: Bool
    let blinkOn: Bool
    /// Base unit, 1/20 of the tube's shorter side.
    let u: CGFloat

    private let phosphor = Color(hex: "#9CFFB8")

    var body: some View {
        VStack(alignment: .leading, spacing: u * 0.55) {
            Text("PAUSED")
                .font(.system(size: u * 1.4, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
                .shadow(color: phosphor.opacity(0.8), radius: 6)
                .frame(maxWidth: .infinity)
                .padding(.bottom, u * 0.3)

            ForEach(PauseMenuItem.allCases, id: \.self) { item in
                row(item)
            }

            Text("START RESUMES")
                .font(.system(size: u * 0.65, weight: .bold, design: .monospaced))
                .foregroundStyle(phosphor.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.top, u * 0.3)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .padding(.horizontal, u * 1.3)
        .padding(.vertical, u * 1.0)
        .background(
            RoundedRectangle(cornerRadius: u * 0.5)
                .fill(Color.black.opacity(0.7))
                .overlay(RoundedRectangle(cornerRadius: u * 0.5).stroke(phosphor.opacity(0.35), lineWidth: 1))
        )
        .padding(u)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Paused. \(selection.title.capitalized) selected. Screen: \(screenModeTitle).")
    }

    private func row(_ item: PauseMenuItem) -> some View {
        let isSelected = item == selection

        return HStack(spacing: u * 0.5) {
            Text("▶")
                .opacity(isSelected ? (blinkOn ? 1 : 0.35) : 0)
            Text(item.title)
            if item == .screen {
                Spacer(minLength: u * 0.5)
                Text(canChangeScreen ? "◀ \(screenModeTitle.uppercased()) ▶" : screenModeTitle.uppercased())
                    .foregroundStyle(phosphor.opacity(isSelected ? 1 : 0.6))
            }
        }
        .font(.system(size: u * 0.85, weight: .bold, design: .monospaced))
        .foregroundStyle(isSelected ? Color.white : phosphor.opacity(0.75))
    }
}
