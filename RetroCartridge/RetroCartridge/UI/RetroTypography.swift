//
// RetroTypography.swift
// RetroCartridge
//
// Text in the overlays and the library follows the reader's text size and
// Bold Text setting while keeping the monospaced retro look. The console
// itself (bezel, tube, silkscreen, cartridge labels) stays as printed: its
// text is part of the hardware and scales with it instead.
//

import SwiftUI

extension View {
    /// Sets a monospaced (by default) system font that grows with Dynamic
    /// Type and gets one step heavier with Bold Text.
    /// - Parameters:
    ///   - size: The point size at the default text size (Large).
    ///   - maxScale: The most the text may grow, so headings keep panels in shape.
    ///   - wraps: Whether text limited to one line may wrap at accessibility
    ///     sizes rather than shrink until it's unreadable.
    func retroFont(
        _ size: CGFloat,
        weight: Font.Weight = .bold,
        design: Font.Design = .monospaced,
        maxScale: CGFloat = 2,
        wraps: Bool = true
    ) -> some View {
        modifier(RetroFont(size: size, weight: weight, design: design, maxScale: maxScale, wraps: wraps))
    }
}

private struct RetroFont: ViewModifier {
    let size: CGFloat
    let weight: Font.Weight
    let design: Font.Design
    let maxScale: CGFloat
    let wraps: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.legibilityWeight) private var legibilityWeight

    func body(content: Content) -> some View {
        let wrapsHere = wraps && dynamicTypeSize.isAccessibilitySize

        content
            .font(.system(
                size: size * min(maxScale, RetroType.scale(for: dynamicTypeSize)),
                weight: RetroType.weight(weight, isBold: legibilityWeight == .bold),
                design: design
            ))
            // Closer to the text than the view's own `lineLimit(1)`, so it wins
            .transformEnvironment(\.lineLimit) { limit in
                if wrapsHere { limit = nil }
            }
    }
}

/// How overlay text follows the reader's settings.
enum RetroType {

    /// How much text grows at a Dynamic Type size, relative to Large (the
    /// default), following the body style (17 pt at Large).
    static func scale(for size: DynamicTypeSize) -> CGFloat {
        switch size {
        case .xSmall: return 14.0 / 17
        case .small: return 15.0 / 17
        case .medium: return 16.0 / 17
        case .large: return 1
        case .xLarge: return 19.0 / 17
        case .xxLarge: return 21.0 / 17
        case .xxxLarge: return 23.0 / 17
        case .accessibility1: return 28.0 / 17
        case .accessibility2: return 33.0 / 17
        case .accessibility3: return 40.0 / 17
        case .accessibility4: return 47.0 / 17
        case .accessibility5: return 53.0 / 17
        @unknown default: return 1
        }
    }

    /// One step heavier with Bold Text.
    static func weight(_ weight: Font.Weight, isBold: Bool) -> Font.Weight {
        guard isBold else { return weight }
        switch weight {
        case .ultraLight: return .thin
        case .thin: return .light
        case .light: return .regular
        case .regular: return .medium
        case .medium: return .semibold
        case .semibold: return .bold
        case .bold: return .heavy
        default: return .black
        }
    }
}
