// RetroCartridgeApp.swift
// RetroCartridge
//
// Main entry point for the Retro Cartridge & Unfold app.
// Configures WindowGroup scene and injects all core managers into the environment.

import SwiftUI

@main
struct RetroCartridgeApp: App {
    
    // MARK: - Core Managers (Application-Scoped)
    
    /// Global application state — active game, selected skin, purchase status.
    @State private var appState = AppState()
    
    /// Posture manager — tracks device posture via Size Classes (per Apple HIG).
    @State private var postureManager = PostureManager()
    
    /// Hinge engine — provides hinge angle data for visual effects ONLY.
    /// NOT used for layout decisions (per Apple HIG).
    @State private var hingeEngine = HingeEngine()
    
    /// Haptic feedback manager — CoreHaptics for button presses and events.
    @State private var hapticManager = HapticManager()
    
    /// Audio manager — 8-bit sound effects and retro chimes.
    @State private var audioManager = AudioManager()
    
    /// Store manager — StoreKit 2 IAP integration.
    @State private var storeManager = StoreManager()
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            AdaptiveConsoleLayout()
                .environment(appState)
                .environment(postureManager)
                .environment(hingeEngine)
                .environment(hapticManager)
                .environment(audioManager)
                .environment(storeManager)
                .onAppear {
                    setupOnLaunch()
                }
        }
    }
    
    // MARK: - Setup
    
    /// One-time initialization on app launch.
    private func setupOnLaunch() {
        // Start haptic engine
        hapticManager.prepareEngine()
        
        // Start listening for hinge angle changes (for shader effects)
        hingeEngine.startListening()
        
        // Load StoreKit products
        Task {
            await storeManager.loadProducts()
        }
        
        // Play startup chime
        audioManager.playStartupChime()
    }
}
