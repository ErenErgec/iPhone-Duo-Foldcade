//
//  PostureManager.swift
//  RetroCartridge
//

import SwiftUI
import Observation

@Observable
final class PostureManager {
    
    /// The current physical device posture based on size classes.
    private(set) var currentPosture: DevicePosture = .closed {
        didSet {
            previousPosture = oldValue
        }
    }
    
    /// The device posture prior to the current one.
    private(set) var previousPosture: DevicePosture?
    
    /// A convenience flag for quick layout checks.
    private(set) var isCompactWidth: Bool = false
    
    init() {}
    
    /// Updates the posture based on Size Classes (per Apple HIG).
    /// Does NOT use hinge angle for posture determination.
    func updatePosture(horizontalSizeClass: UserInterfaceSizeClass?, verticalSizeClass: UserInterfaceSizeClass?) {
        isCompactWidth = horizontalSizeClass == .compact
        
        // Inference of posture from size classes
        if horizontalSizeClass == .compact && verticalSizeClass == .regular {
            currentPosture = .closed
        } else if horizontalSizeClass == .regular && verticalSizeClass == .regular {
            currentPosture = .fullyOpen
        } else {
            currentPosture = .halfOpened
        }
    }
}
