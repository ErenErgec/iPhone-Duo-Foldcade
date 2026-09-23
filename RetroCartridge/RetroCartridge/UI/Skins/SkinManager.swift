//
//  SkinManager.swift
//  RetroCartridge
//
//  Created by AI on 2026-09-22.
//

import SwiftUI

struct SkinTheme: Equatable, Sendable {
    var bodyColor: Color
    var buttonColor: Color
    var accentColor: Color
    var textColor: Color
    var screenBorderColor: Color
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
