//
// AdaptiveConsoleLayout.swift
// RetroCartridge
//

import SwiftUI

public struct AdaptiveConsoleLayout: View {
    @Environment(AppState.self) private var appState
    @Environment(PostureManager.self) private var postureManager
    @Environment(HingeEngine.self) private var hingeEngine
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    public init() {}
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(red: 25/255, green: 28/255, blue: 28/255) // #191C1C
                    .ignoresSafeArea()
                
                if postureManager.isCompactWidth {
                    CoverScreenLayout()
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    FullScreenLayout()
                        .transition(.opacity.combined(with: .scale(scale: 1.05)))
                }
            }
            .animation(.easeInOut(duration: 0.4), value: postureManager.isCompactWidth)
        }
        .onAppear {
            if let hSize = horizontalSizeClass, let vSize = verticalSizeClass {
                postureManager.updatePosture(horizontalSizeClass: hSize, verticalSizeClass: vSize)
            }
        }
        .onChange(of: horizontalSizeClass) { _, newClass in
            if let hSize = newClass, let vSize = verticalSizeClass {
                postureManager.updatePosture(horizontalSizeClass: hSize, verticalSizeClass: vSize)
            }
        }
        .onChange(of: verticalSizeClass) { _, newClass in
            if let hSize = horizontalSizeClass, let vSize = newClass {
                postureManager.updatePosture(horizontalSizeClass: hSize, verticalSizeClass: vSize)
            }
        }
    }
}
