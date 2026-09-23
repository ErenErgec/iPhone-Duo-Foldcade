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
    
    /// Updates the posture from the display the app is on, measured by its full
    /// screen size. Unlike size classes this stays stable when the outer display
    /// is locked to landscape. Anything other than the inner display (including
    /// regular iPhones) uses the compact cover layout.
    func updateDisplay(fullScreenSize: CGSize) {
        let display = DuoDisplay(size: fullScreenSize)
        isCompactWidth = display != .inner
        currentPosture = display == .inner ? .fullyOpen : .closed
    }
    
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

/// Identifies the iPhone Duo display from its full-screen size in points,
/// which works in any orientation. The outer display is a short, wide ~3:2
/// panel (≈466×678 pt) and the inner display is ~3:4 (≈669×871 pt); regular
/// iPhones are much taller (~19.5:9).
enum DuoDisplay: Equatable {
    case outer
    case inner
    case other
    
    init(size: CGSize) {
        let short = min(size.width, size.height)
        let long = max(size.width, size.height)
        guard short > 0, long / short < 1.6 else {
            self = .other
            return
        }
        self = short < 600 ? .outer : .inner
    }
}
