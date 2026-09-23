//
// OverlayPanel.swift
// RetroCartridge
//
// Chrome shared by the in-hierarchy overlays (skin picker, store).
//
// These are deliberately NOT sheets or popovers: UIKit presents those in the
// scene's locked interface orientation, while the console's SwiftUI content is
// counter-rotated by `FixedOrientation`, so a sheet would appear sideways. The
// host (`FullScreenLayout`) stacks an `OverlayBackdrop` and the panel in its
// own ZStack instead, so they rotate with everything else.
//

import SwiftUI

/// Shared colors for the overlay screens.
enum RetroPalette {
    /// CRT phosphor green, as used by the game screen.
    static let phosphor = Color(hex: "#9CFFB8")
    /// Warning amber for connection problems.
    static let amber = Color(hex: "#FFC857")
    /// Error red, matching the Brick Breaker cartridge.
    static let alert = Color(hex: "#FF6B6B")
    /// Panel surface.
    static let panelTop = Color(hex: "#1C2023")
    static let panelBottom = Color(hex: "#0F1113")
}

extension AnyTransition {
    /// Panels rise slightly and fade in; they fall back and fade out.
    static var overlayPanel: AnyTransition {
        .opacity
            .combined(with: .offset(y: 36))
            .combined(with: .scale(scale: 0.97))
    }
}

/// Dimmed backdrop behind an overlay panel. Tapping it dismisses the panel.
struct OverlayBackdrop: View {
    let onDismiss: () -> Void

    var body: some View {
        Color.black.opacity(0.62)
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture(perform: onDismiss)
            .accessibilityLabel("Close")
            .accessibilityAddTraits(.isButton)
    }
}

/// A dark, rounded console-accessory panel with a title bar and a close
/// button. Content that doesn't fit vertically scrolls.
struct OverlayPanel<Content: View>: View {
    let title: String
    let subtitle: String
    let onClose: () -> Void
    @ViewBuilder let content: Content

    @Environment(\.fixedSafeAreaInsets) private var insets

    var body: some View {
        VStack(spacing: 0) {
            header

            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(height: 1)

            ViewThatFits(in: .vertical) {
                content
                    .padding(22)
                ScrollView {
                    content
                        .padding(22)
                }
                .scrollIndicators(.hidden)
            }
        }
        .frame(maxWidth: 580)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [RetroPalette.panelTop, RetroPalette.panelBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.16), .white.opacity(0.03)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.6), radius: 30, y: 16)
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .padding(insets)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onClose)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(RetroPalette.phosphor)
                        .frame(width: 7, height: 7)
                        .shadow(color: RetroPalette.phosphor.opacity(0.8), radius: 4)
                    Text(title)
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .tracking(3)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Text(subtitle)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.45))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 0)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.08)))
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                    .contentShape(Circle())
            }
            .buttonStyle(CartridgePressStyle())
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
    }
}

/// A capsule label used for statuses and small actions in the overlays.
struct RetroCapsuleLabel: View {
    let title: String
    var systemImage: String? = nil
    var tint: Color = .white
    var filled: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .heavy))
            }
            Text(title)
                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                .tracking(2)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(filled ? Color.black.opacity(0.85) : tint)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            Capsule().fill(filled ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.08)))
        )
        .overlay(Capsule().stroke(tint.opacity(filled ? 0 : 0.45), lineWidth: 1))
    }
}
