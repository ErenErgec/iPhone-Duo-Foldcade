//
// ControllerView.swift
// RetroCartridge
//

import SwiftUI

public struct ControllerView: View {
    @Environment(AppState.self) private var appState
    @Environment(HapticManager.self) private var hapticManager
    
    @State private var activeDirection: GameInputAction? = nil
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Controller Background
            SkinManager.theme(for: appState.selectedSkin).bodyColor
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                HStack {
                    // D-Pad
                    dPad
                        .padding(.leading, 30)
                    
                    Spacer()
                    
                    // Action Buttons
                    actionButtons
                        .padding(.trailing, 30)
                }
                
                Spacer()
                
                // Start & Select
                startSelectButtons
                    .padding(.bottom, 20)
            }
            
            // Embossed Label
            Text("RETRO CARTRIDGE")
                .font(.caption.monospaced().bold())
                .foregroundColor(Color(white: 0.2))
                .shadow(color: .white.opacity(0.2), radius: 1, x: 0, y: 1)
                .offset(y: 40)
        }
    }
    
    private var dPad: some View {
        let size: CGFloat = 40
        let totalSize: CGFloat = size * 3
        
        return ZStack {
            // Vertical bar
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: "#2D2D2D"))
                .frame(width: size, height: totalSize)
            
            // Horizontal bar
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: "#2D2D2D"))
                .frame(width: totalSize, height: size)
            
            // Center circle
            Circle()
                .fill(Color(hex: "#202020"))
                .frame(width: size * 0.8, height: size * 0.8)
        }
        .frame(width: totalSize, height: totalSize)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let loc = value.location
                    let center = totalSize / 2
                    let dx = loc.x - center
                    let dy = loc.y - center
                    
                    var newAction: GameInputAction?
                    if abs(dx) > abs(dy) {
                        if dx > size/2 { newAction = .right }
                        else if dx < -size/2 { newAction = .left }
                    } else {
                        if dy > size/2 { newAction = .down }
                        else if dy < -size/2 { newAction = .up }
                    }
                    
                    if newAction != activeDirection {
                        releaseActiveDirection()
                        activeDirection = newAction
                        if let act = newAction {
                            appState.activeGame?.handleInput(action: act)
                            hapticManager.playHaptic(.buttonPress)
                        }
                    }
                }
                .onEnded { _ in
                    releaseActiveDirection()
                    activeDirection = nil
                }
        )
    }

    /// Sends the matching release event for the currently held D-Pad direction,
    /// so games that track held state (e.g. Brick Breaker paddle) stop moving.
    private func releaseActiveDirection() {
        let release: GameInputAction?
        switch activeDirection {
        case .dpadUpPressed: release = .dpadUpReleased
        case .dpadDownPressed: release = .dpadDownReleased
        case .dpadLeftPressed: release = .dpadLeftReleased
        case .dpadRightPressed: release = .dpadRightReleased
        default: release = nil
        }
        if let release {
            appState.activeGame?.handleInput(action: release)
        }
    }
    
    private var actionButtons: some View {
        HStack(alignment: .top, spacing: 20) {
            // B Button (Blue-ish)
            Button {
                appState.activeGame?.handleInput(action: .b)
                hapticManager.playHaptic(.buttonPress)
            } label: {
                Circle()
                    .fill(Color(hex: "#5A82B5"))
                    .frame(width: 45, height: 45)
                    .overlay(Text("B").font(.headline.monospaced().bold()).foregroundColor(.white))
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
            }
            .offset(y: 20)
            
            // A Button (Red-ish)
            Button {
                appState.activeGame?.handleInput(action: .a)
                hapticManager.playHaptic(.buttonPress)
            } label: {
                Circle()
                    .fill(Color(hex: "#C14B4B"))
                    .frame(width: 55, height: 55)
                    .overlay(Text("A").font(.title3.monospaced().bold()).foregroundColor(.white))
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
            }
            .offset(y: -10)
        }
    }
    
    private var startSelectButtons: some View {
        HStack(spacing: 30) {
            // Select — ejects the cartridge and returns to the game menu
            Button {
                appState.activeGame?.handleInput(action: .select)
                hapticManager.playHaptic(.buttonPress)
                appState.endGame()
            } label: {
                Capsule()
                    .fill(Color.gray)
                    .frame(width: 40, height: 12)
                    .rotationEffect(.degrees(-30))
                    .overlay(
                        Text("SELECT")
                            .font(.system(size: 8).monospaced())
                            .foregroundColor(.gray)
                            .offset(y: 20)
                    )
            }
            
            // Start
            Button {
                appState.activeGame?.handleInput(action: .start)
                hapticManager.playHaptic(.buttonPress)
            } label: {
                Capsule()
                    .fill(Color.gray)
                    .frame(width: 40, height: 12)
                    .rotationEffect(.degrees(-30))
                    .overlay(
                        Text("START")
                            .font(.system(size: 8).monospaced())
                            .foregroundColor(.gray)
                            .offset(y: 20)
                    )
            }
        }
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
