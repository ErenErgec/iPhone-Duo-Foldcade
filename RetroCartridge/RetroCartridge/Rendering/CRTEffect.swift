// CRTEffect.swift
// RetroCartridge
//
// SwiftUI bridge that applies the `crtEffect` Metal shader as a layer effect.

import SwiftUI

extension View {

    /// Renders this view through the CRT tube shader.
    /// - Parameters:
    ///   - hingeAngle: Hinge angle in degrees (0 = closed, 180 = flat).
    ///     Used only for the visual curvature, never for layout (per Apple HIG).
    ///   - powerOnProgress: Power-on animation progress from 0 (off) to 1 (on).
    func crtEffect(hingeAngle: Float, powerOnProgress: Double) -> some View {
        let normalizedAngle = Double(max(0, min(1, hingeAngle / 180)))
        // 0 when flat, 1 when closed. Eased so the first few degrees of
        // folding stay gentle and the tube bulges more the further it folds.
        let fold = pow(1 - normalizedAngle, 1.5)
        // Subtle curvature when flat, more pronounced as the device folds.
        let curvature = 0.06 + 0.14 * fold

        return layerEffect(
            ShaderLibrary.crtEffect(
                .boundingRect,
                .float(curvature),
                .float(fold),
                .float(max(0, min(1, powerOnProgress)))
            ),
            maxSampleOffset: CGSize(width: 4, height: 4)
        )
    }
}
