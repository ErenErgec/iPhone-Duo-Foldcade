//
//  SkinManager.swift
//  RetroCartridge
//

import SwiftUI

struct SkinTheme: Equatable, Sendable {
    var bodyColor: Color
    var buttonColor: Color
    var accentColor: Color
    var textColor: Color
    var screenBorderColor: Color
    /// Fill color of the A / B action buttons.
    var actionButtonColor: Color
    var isTranslucent: Bool
}

enum SkinManager {
    static func theme(for skin: ConsoleSkinType) -> SkinTheme {
        switch skin {
        case .classicGrey:
            return .classicGrey
        case .atomicPurple:
            return .atomicPurple
        case .cyberpunkNeon:
            return .cyberpunkNeon
        case .arcadeCabinet:
            return .arcadeCabinet
        }
    }
}
