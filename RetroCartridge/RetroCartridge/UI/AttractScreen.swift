//
// AttractScreen.swift
// RetroCartridge
//
// The cover screen's attract mode: the selected cartridge plays itself
// (`AttractPilot`) through the Color CRT, silently, at 30 FPS. It's purely
// decorative, so it's hidden from accessibility and stays still when
// Reduce Motion is on.
//

import SwiftUI

struct AttractScreen: View {
    let gameType: GameType

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pilot: AttractPilot?

    var body: some View {
        ZStack {
            if !reduceMotion, let pilot {
                TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
                    // Capturing the frame date makes each frame's renderer
                    // distinct, as in `GameCanvasView`.
                    Canvas { [frameDate = timeline.date] context, size in
                        _ = frameDate
                        pilot.game.render(context: &context, size: size)
                    }
                    .onChange(of: timeline.date) { oldDate, newDate in
                        pilot.step(deltaTime: min(max(newDate.timeIntervalSince(oldDate), 0), 0.05))
                    }
                }
                .screenEffect(.standard, hingeAngle: 180, powerOnProgress: 1)
            }
        }
        .onAppear {
            pilot = AttractPilot(type: gameType)
        }
        .onChange(of: gameType) { _, newType in
            pilot = AttractPilot(type: newType)
        }
        .onDisappear {
            pilot = nil
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
