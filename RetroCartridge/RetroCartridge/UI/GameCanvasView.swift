//
// GameCanvasView.swift
// RetroCartridge
//
// The screen half of the console: a molded bezel with power LED around a
// CRT tube that renders the active game at 60 FPS, in-tube messages for the
// title, pause and game-over states, and a score readout on the bezel.
//

import SwiftUI

struct GameCanvasView: View {
    @Environment(AppState.self) private var appState
    @Environment(HingeEngine.self) private var hingeEngine
    @Environment(AudioManager.self) private var audioManager
    @Environment(HapticManager.self) private var hapticManager

    /// When the CRT power-on animation started. This view is created fresh
    /// for each game session, so every cartridge gets its own power-on.
    @State private var powerOnStart = Date()

    /// Duration of the CRT power-on animation, in seconds.
    private let powerOnDuration: TimeInterval = 0.7

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
                            colors: [Color(hex: "#2B2E35"), Color(hex: "#17191D")],
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
                                    highScore: max(appState.highScore(for: activeGame.gameType), activeGame.score),
                                    fontSize: max(10, inset * 0.5)
                                )
                            }
                            .onChange(of: timeline.date) { oldDate, newDate in
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
                                    appState.updateHighScore(score, for: activeGame.gameType)
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

    // MARK: - Bezel

    private func bezelHeader(theme: SkinTheme, inset: CGFloat) -> some View {
        HStack(spacing: 6) {
            // Power LED
            Circle()
                .fill(appState.isGameActive ? Color(hex: "#FF3B30") : Color(white: 0.25))
                .frame(width: 7, height: 7)
                .shadow(color: appState.isGameActive ? Color(hex: "#FF3B30") : .clear, radius: 4)
            Text("POWER")
                .font(.system(size: max(8, inset * 0.36), weight: .bold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.35))

            Spacer()

            Text("COLOR CRT")
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
                    highScore: max(appState.highScore(for: game.gameType), game.score),
                    blinkOn: Int(date.timeIntervalSinceReferenceDate * 2.5) % 2 == 0
                )
            }
            .crtEffect(
                hingeAngle: hingeEngine.hingeAngle,
                powerOnProgress: date.timeIntervalSince(powerOnStart) / powerOnDuration
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

/// Title, pause and game-over messages rendered inside the CRT tube, so they
/// get the same curvature and scanlines as the game itself.
private struct GameStatePanel: View {
    let title: String
    let gameState: GameState
    let highScore: Int
    let blinkOn: Bool

    private let phosphor = Color(hex: "#9CFFB8")

    var body: some View {
        GeometryReader { geo in
            let u = min(geo.size.width, geo.size.height) / 20

            Group {
                switch gameState {
                case .menu:
                    panel(u: u, title: title.uppercased(), lines: [], prompt: "PRESS A TO START")
                case .paused:
                    panel(u: u, title: "PAUSED", lines: [], prompt: "PRESS START")
                case .gameOver(let finalScore):
                    panel(
                        u: u,
                        title: "GAME OVER",
                        lines: finalScore > 0 && finalScore >= highScore ? ["NEW HIGH SCORE!", "\(finalScore)"] : ["SCORE \(finalScore)"],
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

            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.system(size: u * 0.85, weight: .bold, design: .monospaced))
                    .foregroundStyle(phosphor)
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
