// RetroCartridgeApp.swift
// RetroCartridge
//
// Main entry point for the Retro Cartridge & Unfold app.
//
// The app uses a UIKit scene with a SwiftUI root instead of a SwiftUI `App`,
// because its root view controller must lock the interface orientation
// (`prefersInterfaceOrientationLocked`), which SwiftUI's own root can't do.
// With the lock the system never rotates the interface — and never plays a
// rotation animation — while the console is on screen.

import SwiftUI
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = ConsoleHostingController(rootView: RootView())
        window.makeKeyAndVisible()
        self.window = window
    }
}

/// Hosts the SwiftUI console and keeps the system from ever rotating it.
/// `FixedOrientation` pins each layout to its display for whatever
/// orientation the scene happens to be locked in.
///
/// The status bar stays visible: on iPhone Duo it lives in the system's
/// reserved side column (with the camera and Dynamic Island), which apps
/// can't draw into, so hiding it would only leave that column empty.
final class ConsoleHostingController: UIHostingController<RootView> {
    override var prefersInterfaceOrientationLocked: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .all }
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
}

/// Owns the application-scoped managers and injects them into the environment.
struct RootView: View {

    // MARK: - Core Managers (Application-Scoped)

    /// Global application state — active game, selected skin, purchase status.
    @State private var appState = AppState()

    /// Posture manager — tracks which iPhone Duo display the app is on.
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

    var body: some View {
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

    // MARK: - Setup

    /// One-time initialization on app launch.
    private func setupOnLaunch() {
        // Start haptic engine
        hapticManager.prepareEngine()

        // Chime and click when the hinge swings past 90° while unfolding
        hingeEngine.onUnfoldPast90Degrees = { [audioManager, hapticManager] in
            audioManager.playHingeSnap()
            hapticManager.playHaptic(.hingeClick)
        }

        // Start deriving the hinge angle from the display posture (for shader effects)
        hingeEngine.startListening(following: postureManager)

        // Load StoreKit products
        Task {
            await storeManager.loadProducts()
        }

        // Play startup chime
        audioManager.playStartupChime()
    }
}
