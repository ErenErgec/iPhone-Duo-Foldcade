//
// GameCanvasView.swift
// RetroCartridge
//
// The screen half of the console: a molded bezel with power LED around a
// CRT tube that renders the active game at 60 FPS, in-tube messages for the
// title and game-over states, the pause menu, and a score readout on the
// bezel. Ejecting powers the tube off before the cartridge comes out.
//

import SwiftUI

struct GameCanvasView: View {
    @Environment(AppState.self) private var appState
    @Environment(HingeEngine.self) private var hingeEngine
    @Environment(AudioManager.self) private var audioManager
    @Environment(HapticManager.self) private var hapticManager
    @Environment(StoreManager.self) private var storeManager

    /// When the CRT power-on animation started. This view is created fresh
    /// for each game session, so every cartridge gets its own power-on.
    @State private var powerOnStart = Date()

    /// Duration of the CRT power-on animation, in seconds.
    private let powerOnDuration: TimeInterval = 0.7

    /// Duration of the power-off animation when ejecting, in seconds.
    private let powerOffDuration: TimeInterval = 0.45

    /// Handheld-style, slightly wider than square (Game Boy screens are 10:9).
    private let screenAspectRatio: CGFloat = 10 / 9

    init() {}

    var body: some View {
        let theme = SkinManager.theme(for: appState.selectedSkin)

        GeometryReader { geo in
            let inset = min(geo.size.width, geo.size.height) * 0.05

            ZStack {
                // Bezel
                RoundedRectangle(cornerRadius: inset * 1.4, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [theme.bezelTopColor, theme.bezelBottomColor],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: inset * 1.4, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 6, y: 3)

                VStack(spacing: inset * 0.6) {
                    bezelHeader(theme: theme, inset: inset)

                    if let activeGame = appState.activeGame {
                        TimelineView(.animation) { timeline in
                            VStack(spacing: inset * 0.6) {
                                screen(game: activeGame, date: timeline.date)
                                    .aspectRatio(screenAspectRatio, contentMode: .fit)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                                BezelReadout(
                                    score: activeGame.score,
                                    level: activeGame.level,
                                    highScore: max(appState.highScore(for: activeGame.gameType, mode: activeGame.mode), activeGame.score),
                                    fontSize: max(10, inset * 0.5)
                                )
                            }
                            .onChange(of: timeline.date) { oldDate, newDate in
                                // Ejecting: the game stays frozen while the tube powers off
                                if let ejectStart = appState.ejectStart {
                                    if newDate.timeIntervalSince(ejectStart) >= powerOffDuration {
                                        appState.endGame()
                                    }
                                    return
                                }

                                let delta = newDate.timeIntervalSince(oldDate)
                                activeGame.update(deltaTime: min(max(delta, 0), 0.05))

                                // Play the sound effects raised by this frame's update and by
                                // any input since the last frame, with one haptic for big events.
                                let sounds = activeGame.drainSounds()
                                for sound in sounds {
                                    audioManager.playGameSound(sound)
                                }
                                if sounds.contains(where: \.isImpactful) {
                                    hapticManager.playHaptic(.gameEvent)
                                }

                                // Persist the score as soon as a round ends, since pressing A
                                // restarts the game and resets its score.
                                if case .gameOver(let score) = activeGame.gameState {
                                    appState.updateHighScore(score, for: activeGame.gameType, mode: activeGame.mode)
                                }
                            }
                        }
                    }
                }
                .padding(inset)
            }
            .padding(inset)
        }
    }

    /// Tube power from 0 (off) to 1 (on): rising at power-on, falling back
    /// while the cartridge is ejected, which plays the power-on in reverse.
    private func tubePower(at date: Date) -> Double {
        if let ejectStart = appState.ejectStart {
            return 1 - date.timeIntervalSince(ejectStart) / powerOffDuration
        }
        return date.timeIntervalSince(powerOnStart) / powerOnDuration
    }

    /// The screen to draw, limited to what the player has unlocked.
    private var screenSettings: ScreenSettings {
        storeManager.effectiveScreenSettings(appState.screenSettings)
    }

    // MARK: - Bezel

    private func bezelHeader(theme: SkinTheme, inset: CGFloat) -> some View {
        HStack(spacing: 6) {
            // Power LED
            Circle()
                .fill(appState.isGameActive ? theme.ledColor : Color(white: 0.25))
                .frame(width: 7, height: 7)
                .shadow(color: appState.isGameActive ? theme.ledColor : .clear, radius: 4)
            Text("POWER")
                .font(.system(size: max(8, inset * 0.36), weight: .bold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.35))

            Spacer()

            Text(screenSettings.mode.bezelLabel)
                .font(.system(size: max(8, inset * 0.36), weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(Color.white.opacity(0.3))
            Rectangle()
                .fill(theme.actionButtonColor.opacity(0.8))
                .frame(width: inset * 2, height: 2)
            Rectangle()
                .fill(theme.accentColor.opacity(0.8))
                .frame(width: inset * 1.2, height: 2)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Screen

    private func screen(game: any PixelGameProtocol, date: Date) -> some View {
        ZStack {
            // Tube glass behind the picture
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black)

            ZStack {
                // Capturing the frame date makes each frame's renderer distinct.
                // Otherwise SwiftUI sees an unchanged closure (it only captures
                // the same game object) and keeps showing the first frame.
                Canvas { [frameDate = date] context, size in
                    _ = frameDate
                    game.render(context: &context, size: size)
                }

                GameStatePanel(
                    title: game.gameType.rawValue,
                    gameState: game.gameState,
                    highScore: max(appState.highScore(for: game.gameType, mode: game.mode), game.score),
                    blinkOn: Int(date.timeIntervalSinceReferenceDate * 2.5) % 2 == 0,
                    mode: game.mode,
                    hasModes: game.gameType.modes.count > 1,
                    menuSelection: appState.pauseMenuSelection,
                    screenModeTitle: screenSettings.mode.title,
                    canChangeScreen: PauseMenu.availableScreenModes(store: storeManager).count > 1,
                    paletteTitle: appState.paletteChoice.title
                )
            }
            .screenEffect(
                screenSettings,
                hingeAngle: hingeEngine.hingeAngle,
                powerOnProgress: tubePower(at: date)
            )
            .padding(3)

            // Glass reflection
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.07), .clear, .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Readout

/// Segment-display style score strip printed on the bezel under the tube.
private struct BezelReadout: View {
    let score: Int
    let level: Int
    let highScore: Int
    let fontSize: CGFloat

    private let phosphor = Color(hex: "#9CFFB8")

    var body: some View {
        HStack(spacing: fontSize * 1.6) {
            item("SCORE", String(format: "%06d", score))
            item("LV", String(format: "%02d", level))
            item("HI", String(format: "%06d", highScore))
        }
        .font(.system(size: fontSize, weight: .bold, design: .monospaced))
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }

    private func item(_ label: String, _ value: String) -> some View {
        HStack(spacing: fontSize * 0.4) {
            Text(label)
                .foregroundStyle(Color.white.opacity(0.35))
            Text(value)
                .foregroundStyle(phosphor)
                .shadow(color: phosphor.opacity(0.6), radius: 3)
        }
    }
}

// MARK: - State Panel

/// Title and game-over messages and the pause menu, rendered inside the
/// tube so they get the same curvature and scanlines as the game itself.
private struct GameStatePanel: View {
    let title: String
    let gameState: GameState
    let highScore: Int
    let blinkOn: Bool
    let mode: GameMode
    /// Whether the D-Pad can switch modes on the title and game-over screens.
    let hasModes: Bool
    let menuSelection: PauseMenuItem
    let screenModeTitle: String
    let canChangeScreen: Bool
    let paletteTitle: String

    private let phosphor = Color(hex: "#9CFFB8")

    var body: some View {
        GeometryReader { geo in
            let u = min(geo.size.width, geo.size.height) / 20

            Group {
                switch gameState {
                case .menu:
                    // The D-Pad picks the mode on the title screen
                    panel(
                        u: u,
                        title: title.uppercased(),
                        lines: hasModes ? ["◀ \(mode.title.uppercased()) ▶", mode.summary.uppercased()] : [],
                        prompt: "PRESS A TO START"
                    )
                case .paused:
                    PauseMenuPanel(
                        selection: menuSelection,
                        screenModeTitle: screenModeTitle,
                        canChangeScreen: canChangeScreen,
                        paletteTitle: paletteTitle,
                        blinkOn: blinkOn,
                        u: u
                    )
                case .gameOver(let finalScore):
                    panel(
                        u: u,
                        title: "GAME OVER",
                        lines: (finalScore > 0 && finalScore >= highScore ? ["NEW HIGH SCORE!", "\(finalScore)"] : ["SCORE \(finalScore)"])
                            + (hasModes ? ["◀ \(mode.title.uppercased()) ▶"] : []),
                        prompt: "PRESS A TO RETRY"
                    )
                case .playing:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(false)
    }

    private func panel(u: CGFloat, title: String, lines: [String], prompt: String) -> some View {
        VStack(spacing: u * 0.6) {
            Text(title)
                .font(.system(size: u * 1.5, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
                .shadow(color: phosphor.opacity(0.8), radius: 6)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.system(size: u * 0.85, weight: .bold, design: .monospaced))
                    .foregroundStyle(phosphor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            Text(prompt)
                .font(.system(size: u * 0.8, weight: .bold, design: .monospaced))
                .foregroundStyle(phosphor)
                .opacity(blinkOn ? 1 : 0.15)
                .padding(.top, u * 0.4)
        }
        .padding(.horizontal, u * 1.5)
        .padding(.vertical, u * 1.2)
        .background(
            RoundedRectangle(cornerRadius: u * 0.5)
                .fill(Color.black.opacity(0.65))
                .overlay(RoundedRectangle(cornerRadius: u * 0.5).stroke(phosphor.opacity(0.35), lineWidth: 1))
        )
        .padding(u)
    }
}
