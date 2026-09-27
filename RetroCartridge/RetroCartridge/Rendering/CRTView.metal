// CRTView.metal
// RetroCartridge
//
// SwiftUI layer-effect shader that renders the game canvas through a
// curved CRT tube: barrel distortion, power-on beam, chromatic aberration,
// phosphor glow, scanlines and vignette.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

/// - Parameters:
///   - position: Current pixel position in the view's user space (points).
///   - layer: The rasterized game canvas.
///   - bounds: The view's bounding rect (x, y, width, height).
///   - curvature: Barrel distortion strength (driven by the hinge angle).
///   - fold: How far the device is folded, 0 = flat, 1 = closed. Deepens the
///     scanlines and the vignette as the device folds.
///   - powerOn: Power-on animation progress, 0 = off, 1 = fully on.
[[ stitchable ]] half4 crtEffect(float2 position,
                                 SwiftUI::Layer layer,
                                 float4 bounds,
                                 float curvature,
                                 float fold,
                                 float powerOn) {
    float2 size = bounds.zw;
    float2 uv = (position - bounds.xy) / size;

    // 1. Barrel Distortion (CRT Curvature)
    float2 centered = uv * 2.0 - 1.0;
    float2 curved = centered + centered * dot(centered, centered) * curvature;

    // Transparent outside the curved tube so the bezel behind shows through
    if (abs(curved.x) > 1.0 || abs(curved.y) > 1.0) {
        return half4(0.0);
    }

    // 2. Power-On: a horizontal beam widens, then opens vertically
    if (powerOn < 1.0) {
        float beamWidth = max(smoothstep(0.0, 0.3, powerOn), 0.02);
        float beamHeight = max(smoothstep(0.3, 0.7, powerOn), 0.004);
        if (abs(curved.x) > beamWidth || abs(curved.y) > beamHeight) {
            return half4(0.0, 0.0, 0.0, 1.0);
        }
    }

    float2 samplePos = bounds.xy + (curved * 0.5 + 0.5) * size;

    // 3. Chromatic Aberration, growing towards the tube edges
    float2 aberration = curved * curvature * 6.0;
    float3 color = float3(layer.sample(samplePos + aberration).r,
                          layer.sample(samplePos).g,
                          layer.sample(samplePos - aberration).b);

    // 4. Phosphor Glow
    float3 glow = float3(layer.sample(samplePos + float2( 1.5,  1.5)).rgb)
                + float3(layer.sample(samplePos + float2(-1.5, -1.5)).rgb)
                + float3(layer.sample(samplePos + float2( 1.5, -1.5)).rgb)
                + float3(layer.sample(samplePos + float2(-1.5,  1.5)).rgb);
    color = mix(color, glow * 0.25, 0.2);

    // 5. Scanlines (one dark line every 3pt)
    float scanline = 0.5 + 0.5 * sin(position.y * M_PI_F / 1.5);
    color *= 1.0 - (0.18 + 0.10 * fold) * scanline;

    // 6. Vignette
    color *= 1.0 - smoothstep(0.7 - 0.15 * fold, 1.45, length(curved));

    // Power-on white flash fading into the picture
    if (powerOn < 1.0) {
        color = mix(color, float3(1.0), 1.0 - smoothstep(0.55, 1.0, powerOn));
    }

    return half4(half3(color), 1.0);
}
