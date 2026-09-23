// CRTOverlayView.swift
// RetroCartridge
//
// SwiftUI wrapper for the Metal CRT rendering MTKView.

import SwiftUI
import MetalKit

struct CRTOverlayView: UIViewRepresentable {
    
    // Assuming HingeEngine and AppState are provided as Environment objects globally
    @Environment(HingeEngine.self) private var hingeEngine
    @Environment(AppState.self) private var appState
    
    init() {}
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        
        // Basic configuration
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.colorPixelFormat = .bgra8Unorm
        
        // The background needs to be transparent to overlay the canvas properly
        mtkView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        mtkView.isOpaque = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        // Sync environment values to the Metal renderer
        context.coordinator.hingeAngle = Float(hingeEngine.hingeAngle)
        context.coordinator.powerOnProgress = appState.hasPoweredOn ? 1.0 : 0.0
        
        // Sync performance preferences
        uiView.preferredFramesPerSecond = context.coordinator.preferredFrameRate
    }
    
    func makeCoordinator() -> CRTShaderEngine {
        return CRTShaderEngine()
    }
}
