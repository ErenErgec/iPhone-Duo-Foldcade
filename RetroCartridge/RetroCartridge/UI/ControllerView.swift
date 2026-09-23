//
// ControllerView.swift
// RetroCartridge
//
// Handheld-style control deck: D-Pad, staggered A/B buttons, Select/Start
// pills and a speaker grille, filling the lower half of the unfolded display.
// Sizes scale with the available space.
//

import SwiftUI

public struct ControllerView: View {
    @Environment(AppState.self) private var appState
    @Environment(HapticManager.self) private var hapticManager

    public init() {}

    public var body: some View {
        let theme = SkinManager.theme(for: appState.selectedSkin)

        GeometryReader { geo in
            let unit = min(geo.size.width / 5.2, geo.size.height / 4.2, 110)

            ZStack {
                VStack(spacing: 0) {
                    Spacer(minLength: unit * 0.2)

                    brandLabel(theme: theme, unit: unit)

                    Spacer(minLength: unit * 0.3)

                    HStack(alignment: .center) {
                        DPadView(size: unit * 1.75, theme: theme) { action in
                            press(action)
                        } onRelease: { action in
                            appState.activeGame?.handleInput(action: action)
                        }

                        Spacer(minLength: unit * 0.3)

                        actionButtons(theme: theme, unit: unit)
                    }
                    .padding(.horizontal, unit * 0.35)

                    Spacer(minLength: unit * 0.3)

                    startSelectButtons(theme: theme, unit: unit)

                    Spacer(minLength: unit * 0.35)
                }

                SpeakerGrille(unit: unit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(unit * 0.3)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Input

    private func press(_ action: GameInputAction) {
        appState.activeGame?.handleInput(action: action)
        hapticManager.playHaptic(.buttonPress)
    }

    // MARK: - Pieces

    private func brandLabel(theme: SkinTheme, unit: CGFloat) -> some View {
        HStack(spacing: unit * 0.08) {
            Circle()
                .fill(theme.actionButtonColor)
                .frame(width: unit * 0.09, height: unit * 0.09)
            Text("RETRO")
                .font(.system(size: unit * 0.17, weight: .black, design: .rounded))
                .italic()
            Text("CARTRIDGE")
                .font(.system(size: unit * 0.17, weight: .medium, design: .monospaced))
                .tracking(unit * 0.02)
        }
        .foregroundStyle(theme.textColor.opacity(0.7))
        .shadow(color: .white.opacity(0.15), radius: 0, y: 1)
    }

    private func actionButtons(theme: SkinTheme, unit: CGFloat) -> some View {
        HStack(alignment: .top, spacing: unit * 0.22) {
            ConsoleButton {
                press(.buttonBPressed)
            } onRelease: {
                appState.activeGame?.handleInput(action: .buttonBReleased)
            } label: { isPressed in
                RoundActionButton(letter: "B", size: unit * 0.78, theme: theme, isPressed: isPressed)
            }
            .offset(y: unit * 0.3)

            ConsoleButton {
                press(.buttonAPressed)
            } onRelease: {
                appState.activeGame?.handleInput(action: .buttonAReleased)
            } label: { isPressed in
                RoundActionButton(letter: "A", size: unit * 0.78, theme: theme, isPressed: isPressed)
            }
            .offset(y: -unit * 0.15)
        }
        .rotationEffect(.degrees(-8))
    }

    private func startSelectButtons(theme: SkinTheme, unit: CGFloat) -> some View {
        HStack(spacing: unit * 0.45) {
            ConsoleButton {
                // Select ejects the cartridge and returns to the game menu
                press(.buttonSelectPressed)
                appState.endGame()
            } label: { isPressed in
                PillButton(title: "SELECT", unit: unit, theme: theme, isPressed: isPressed)
            }

            ConsoleButton {
                press(.buttonStartPressed)
            } label: { isPressed in
                PillButton(title: "START", unit: unit, theme: theme, isPressed: isPressed)
            }
        }
    }
}

// MARK: - Press-driven button

/// Fires `onPress` the moment a finger touches down (not on lift, like a
/// SwiftUI `Button`), which keeps game input latency as low as possible.
struct ConsoleButton<Label: View>: View {
    let onPress: () -> Void
    var onRelease: () -> Void = {}
    @ViewBuilder let label: (_ isPressed: Bool) -> Label

    @State private var isPressed = false

    var body: some View {
        label(isPressed)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isPressed else { return }
                        isPressed = true
                        onPress()
                    }
                    .onEnded { _ in
                        isPressed = false
                        onRelease()
                    }
            )
    }
}

// MARK: - D-Pad

struct DPadView: View {
    let size: CGFloat
    let theme: SkinTheme
    let onPress: (GameInputAction) -> Void
    let onRelease: (GameInputAction) -> Void

    @State private var activeDirection: GameInputAction?

    var body: some View {
        let arm = size / 3

        ZStack {
            // Recessed well molded into the shell
            Circle()
                .fill(Color.black.opacity(0.12))
                .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1).offset(y: 1))
                .frame(width: size * 1.14, height: size * 1.14)

            ZStack {
                cross(arm: arm)
                    .fill(theme.buttonColor)
                    .overlay(
                        cross(arm: arm).fill(
                            LinearGradient(
                                colors: [.white.opacity(0.14), .clear, .black.opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    )
                    .shadow(color: .black.opacity(0.45), radius: 3, y: 3)

                // Direction arrows
                ForEach(Array(arrows.enumerated()), id: \.offset) { _, item in
                    Image(systemName: "arrowtriangle.\(item.symbol).fill")
                        .font(.system(size: arm * 0.26))
                        .foregroundStyle(Color.white.opacity(activeDirection == item.action ? 0.4 : 0.16))
                        .offset(x: item.offset.x * arm, y: item.offset.y * arm)
                }

                // Center dimple
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.black.opacity(0.35), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: arm * 0.35
                        )
                    )
                    .frame(width: arm * 0.7, height: arm * 0.7)
            }
            .rotation3DEffect(tilt.angle, axis: tilt.axis, perspective: 0.6)
            .animation(.spring(response: 0.15, dampingFraction: 0.7), value: activeDirection)
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let dx = value.location.x - size / 2
                    let dy = value.location.y - size / 2
                    let deadzone = arm * 0.3

                    var newDirection: GameInputAction?
                    if abs(dx) > abs(dy) {
                        if dx > deadzone { newDirection = .dpadRightPressed }
                        else if dx < -deadzone { newDirection = .dpadLeftPressed }
                    } else {
                        if dy > deadzone { newDirection = .dpadDownPressed }
                        else if dy < -deadzone { newDirection = .dpadUpPressed }
                    }

                    if newDirection != activeDirection {
                        releaseActiveDirection()
                        activeDirection = newDirection
                        if let newDirection { onPress(newDirection) }
                    }
                }
                .onEnded { _ in
                    releaseActiveDirection()
                    activeDirection = nil
                }
        )
    }

    /// Sends the matching release event for the held direction, so games that
    /// track held state (e.g. the Brick Breaker paddle) stop moving.
    private func releaseActiveDirection() {
        switch activeDirection {
        case .dpadUpPressed: onRelease(.dpadUpReleased)
        case .dpadDownPressed: onRelease(.dpadDownReleased)
        case .dpadLeftPressed: onRelease(.dpadLeftReleased)
        case .dpadRightPressed: onRelease(.dpadRightReleased)
        default: break
        }
    }

    private func cross(arm: CGFloat) -> some Shape {
        CrossShape(armWidth: arm, cornerRadius: arm * 0.18)
    }

    private var arrows: [(symbol: String, action: GameInputAction, offset: CGPoint)] {
        [
            ("up", .dpadUpPressed, CGPoint(x: 0, y: -1.05)),
            ("down", .dpadDownPressed, CGPoint(x: 0, y: 1.05)),
            ("left", .dpadLeftPressed, CGPoint(x: -1.05, y: 0)),
            ("right", .dpadRightPressed, CGPoint(x: 1.05, y: 0))
        ]
    }

    /// The cross rocks toward the pressed direction, like a real pivoting D-Pad.
    private var tilt: (angle: Angle, axis: (x: CGFloat, y: CGFloat, z: CGFloat)) {
        let degrees = 12.0
        switch activeDirection {
        case .dpadUpPressed: return (.degrees(degrees), (1, 0, 0))
        case .dpadDownPressed: return (.degrees(-degrees), (1, 0, 0))
        case .dpadLeftPressed: return (.degrees(-degrees), (0, 1, 0))
        case .dpadRightPressed: return (.degrees(degrees), (0, 1, 0))
        default: return (.zero, (1, 0, 0))
        }
    }
}

/// A plus-shaped D-Pad outline with rounded arm tips.
struct CrossShape: Shape {
    var armWidth: CGFloat
    var cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let vertical = CGRect(x: rect.midX - armWidth / 2, y: rect.minY, width: armWidth, height: rect.height)
        let horizontal = CGRect(x: rect.minX, y: rect.midY - armWidth / 2, width: rect.width, height: armWidth)
        return Path(roundedRect: vertical, cornerRadius: cornerRadius)
            .union(Path(roundedRect: horizontal, cornerRadius: cornerRadius))
    }
}

// MARK: - Buttons

struct RoundActionButton: View {
    let letter: String
    let size: CGFloat
    let theme: SkinTheme
    let isPressed: Bool

    var body: some View {
        VStack(spacing: size * 0.14) {
            ZStack {
                // Molded well
                Circle()
                    .fill(Color.black.opacity(0.14))
                    .overlay(Circle().stroke(Color.white.opacity(0.16), lineWidth: 1).offset(y: 1))
                    .frame(width: size * 1.16, height: size * 1.16)

                Circle()
                    .fill(theme.actionButtonColor)
                    .overlay(
                        Circle().fill(
                            RadialGradient(
                                colors: [.white.opacity(0.35), .clear],
                                center: UnitPoint(x: 0.35, y: 0.28),
                                startRadius: 0,
                                endRadius: size * 0.55
                            )
                        )
                    )
                    .overlay(
                        Circle().fill(
                            LinearGradient(colors: [.clear, .black.opacity(0.25)], startPoint: .top, endPoint: .bottom)
                        )
                    )
                    .overlay(Circle().stroke(Color.black.opacity(0.3), lineWidth: 1))
                    .frame(width: size, height: size)
                    .shadow(color: .black.opacity(isPressed ? 0.2 : 0.45), radius: isPressed ? 1 : 4, y: isPressed ? 1 : 4)
                    .scaleEffect(isPressed ? 0.93 : 1)
                    .offset(y: isPressed ? 2 : 0)
            }

            Text(letter)
                .font(.system(size: size * 0.26, weight: .heavy, design: .rounded))
                .foregroundStyle(theme.textColor.opacity(0.7))
        }
        .animation(.spring(response: 0.12, dampingFraction: 0.6), value: isPressed)
    }
}

struct PillButton: View {
    let title: String
    let unit: CGFloat
    let theme: SkinTheme
    let isPressed: Bool

    var body: some View {
        VStack(spacing: unit * 0.14) {
            Capsule()
                .fill(theme.buttonColor.opacity(0.85))
                .overlay(Capsule().fill(LinearGradient(colors: [.white.opacity(0.15), .clear], startPoint: .top, endPoint: .bottom)))
                .frame(width: unit * 0.58, height: unit * 0.17)
                .shadow(color: .black.opacity(isPressed ? 0.1 : 0.35), radius: isPressed ? 0.5 : 2, y: isPressed ? 0.5 : 2)
                .offset(y: isPressed ? 1.5 : 0)
                .rotationEffect(.degrees(-25))

            Text(title)
                .font(.system(size: unit * 0.12, weight: .bold, design: .monospaced))
                .tracking(unit * 0.015)
                .foregroundStyle(theme.textColor.opacity(0.6))
        }
        .padding(unit * 0.08)
        .animation(.spring(response: 0.12, dampingFraction: 0.6), value: isPressed)
    }
}

/// Diagonal speaker slots in the corner of the shell.
struct SpeakerGrille: View {
    let unit: CGFloat

    var body: some View {
        HStack(spacing: unit * 0.1) {
            ForEach(0..<6, id: \.self) { _ in
                Capsule()
                    .fill(Color.black.opacity(0.22))
                    .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5).offset(y: 0.75))
                    .frame(width: unit * 0.07, height: unit * 0.75)
            }
        }
        .rotationEffect(.degrees(-30))
    }
}

// Helper extension for Color from hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
