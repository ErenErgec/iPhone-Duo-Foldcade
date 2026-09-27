//
// CartridgeView.swift
// RetroCartridge
//
// A retro game cartridge drawn in SwiftUI: a molded plastic shell with grip
// ridges, a notched corner and a colored label carrying the game's artwork.
//

import SwiftUI

struct CartridgeView: View {
    let game: GameType

    /// Shown on the label when non-nil and greater than zero.
    var highScore: Int? = nil

    /// Selected cartridges cast a larger, softer shadow.
    var isSelected: Bool = false

    /// Width / height of the cartridge shell.
    static let aspectRatio: CGFloat = 0.8

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let labelColor = Color(hex: game.cartridgeColorHex)

            ZStack(alignment: .top) {
                // Shell
                CartridgeShape(notch: w * 0.13)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.36), Color(white: 0.24)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        CartridgeShape(notch: w * 0.13)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.25), .white.opacity(0.02)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: labelColor.opacity(isSelected ? 0.35 : 0), radius: 30)
                    .shadow(color: .black.opacity(0.55), radius: isSelected ? 16 : 8, y: isSelected ? 12 : 6)

                VStack(spacing: h * 0.04) {
                    // Grip ridges
                    VStack(spacing: h * 0.018) {
                        ForEach(0..<4, id: \.self) { _ in
                            Capsule()
                                .fill(Color.black.opacity(0.3))
                                .overlay(Capsule().stroke(Color.white.opacity(0.06), lineWidth: 0.5).offset(y: 0.75))
                                .frame(height: max(1.5, h * 0.012))
                        }
                    }
                    .padding(.horizontal, w * 0.24)
                    .padding(.top, h * 0.055)

                    // Label
                    ZStack {
                        RoundedRectangle(cornerRadius: w * 0.05, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [labelColor.opacity(0.85), labelColor],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        // Retro racing stripes across the label
                        VStack(spacing: h * 0.012) {
                            ForEach(0..<3, id: \.self) { i in
                                Rectangle()
                                    .fill(Color.white.opacity(0.18 - Double(i) * 0.05))
                                    .frame(height: h * 0.012)
                            }
                        }
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, h * 0.05)

                        VStack(spacing: h * 0.025) {
                            Image(systemName: game.symbolName)
                                .font(.system(size: w * 0.2, weight: .bold))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.25), radius: 2, y: 2)

                            Text(game.rawValue.uppercased())
                                .font(.system(size: w * 0.075, weight: .heavy, design: .monospaced))
                                .foregroundStyle(Color.black.opacity(0.78))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .padding(.horizontal, w * 0.04)
                        }
                        .padding(.bottom, h * 0.04)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: w * 0.05, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: w * 0.05, style: .continuous)
                            .stroke(Color.black.opacity(0.35), lineWidth: 1)
                    )
                    .frame(height: h * 0.5)
                    .padding(.horizontal, w * 0.1)

                    // Embossed footer
                    VStack(spacing: h * 0.012) {
                        Text("RETRO CARTRIDGE")
                            .font(.system(size: w * 0.05, weight: .bold, design: .monospaced))
                            .tracking(w * 0.006)
                            .foregroundStyle(Color.black.opacity(0.45))
                            .shadow(color: .white.opacity(0.12), radius: 0, y: 0.5)

                        if let highScore, highScore > 0 {
                            Text("HI \(highScore)")
                                .font(.system(size: w * 0.055, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.6))
                        }
                    }

                    Spacer(minLength: 0)
                }
            }
        }
        .aspectRatio(Self.aspectRatio, contentMode: .fit)
    }
}

/// Cartridge silhouette: rounded corners with a diagonal notch at the top-right.
struct CartridgeShape: Shape {
    var notch: CGFloat

    func path(in r: CGRect) -> Path {
        let c = min(r.width, r.height) * 0.06
        var p = Path()
        p.move(to: CGPoint(x: r.minX + c, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - notch, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + notch))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - c))
        p.addQuadCurve(to: CGPoint(x: r.maxX - c, y: r.maxY), control: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + c, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY - c), control: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + c))
        p.addQuadCurve(to: CGPoint(x: r.minX + c, y: r.minY), control: CGPoint(x: r.minX, y: r.minY))
        p.closeSubpath()
        return p
    }
}

/// Press feedback for cartridges: sinks slightly as if pushed into the slot.
struct CartridgePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .offset(y: configuration.isPressed ? 4 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Dark studio backdrop with a soft glow tinted by the selected game.
struct ConsoleBackdrop: View {
    var glowColor: Color

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#15181A"), Color(hex: "#0A0B0C")],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [glowColor.opacity(0.22), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 420
            )
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.4), value: glowColor)
    }
}
