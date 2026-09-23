//
// ReservedRegionManager.swift
// RetroCartridge
//

import SwiftUI
import CoreGraphics

/// Manages reserved regions for device form factors like the iPhone Duo hinge.
/// Note: This uses sensible defaults and will be updated when the real Reserved Regions API
/// from iOS 27.1 becomes available.
@Observable
public final class ReservedRegionManager {
    
    public init() {}
    
    /// The reserved region for the physical fold/hinge.
    /// Currently defaults to an 8pt wide region centered horizontally.
    public var hingeRegion: CGRect? = nil
    
    /// Calculates the safe game area avoiding the hinge region if applicable.
    /// - Parameter totalSize: The total size of the container.
    /// - Returns: A CGRect representing the usable area.
    public func safeGameArea(in totalSize: CGSize) -> CGRect {
        let width = totalSize.width
        let height = totalSize.height
        
        // Approximate hinge area (8pt centered horizontally)
        let hingeWidth: CGFloat = 8.0
        let hingeRect = CGRect(x: (width - hingeWidth) / 2, y: 0, width: hingeWidth, height: height)
        
        self.hingeRegion = hingeRect
        
        // Return full bounds for now since we generally use top/bottom split on Duo,
        // so horizontal center hinge won't cut through the canvas if used in upper half.
        // For a full screen spread, this would be computed differently.
        return CGRect(origin: .zero, size: totalSize)
    }
}
