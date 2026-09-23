//
//  HingeEngine.swift
//  RetroCartridge
//

import SwiftUI
import Observation

@Observable
final class HingeEngine {
    
    /// The current hinge angle (0.0 = closed, 180.0 = fully flat).
    /// Used ONLY for visual effects (CRT shader uniforms, parallax).
    /// MUST NOT be used for layout decisions.
    private(set) var hingeAngle: Float = 0.0 {
        didSet {
            normalizedAngle = hingeAngle / 180.0
            isPast90Degrees = hingeAngle >= 90.0
            isUnfolding = hingeAngle > oldValue
        }
    }
    
    /// Normalized angle from 0.0 to 1.0 for easy shader interpolation.
    private(set) var normalizedAngle: Float = 0.0
    
    /// Indicates if the angle crossed the 90 degree threshold (useful for audio triggers).
    private(set) var isPast90Degrees: Bool = false
    
    /// Indicates if the device is currently unfolding.
    private(set) var isUnfolding: Bool = false
    
    /// If true, the simulated angle is used for testing in simulator/debug mode.
    var isSimulated: Bool = false
    
    /// Provides a way to manually control the angle when simulated.
    var simulatedAngle: Float = 0.0 {
        didSet {
            if isSimulated {
                hingeAngle = simulatedAngle
            }
        }
    }
    
    init() {}
    
    /// Starts listening to hardware hinge angle updates.
    func startListening() {
        #if targetEnvironment(simulator)
        isSimulated = true
        #else
        // In a production device, we hook up to the iOS 27 hinge angle API here.
        isSimulated = false
        #endif
    }
    
    /// Stops listening to hardware hinge angle updates.
    func stopListening() {
        // Disconnect from system hinge angle API.
    }
}
