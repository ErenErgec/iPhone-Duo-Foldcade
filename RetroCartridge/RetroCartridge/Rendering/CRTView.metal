// CRTView.metal
// RetroCartridge
//
// Metal shaders for rendering realistic CRT effects.

#include <metal_stdlib>
using namespace metal;

struct CRTUniforms {
    float2 resolution;
    float hingeAngle;
    float normalizedAngle;
    float time;
    float scanlineDensity;
    float curvatureStrength;
    float chromaticAberrationOffset;
    float glowIntensity;
    float powerOnProgress;
};

struct CRTVertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex CRTVertexOut crtVertexShader(uint vertexID [[vertex_id]]) {
    const float2 positions[4] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2( 1.0,  1.0)
    };
    
    const float2 texCoords[4] = {
        float2(0.0, 1.0),
        float2(1.0, 1.0),
        float2(0.0, 0.0),
        float2(1.0, 0.0)
    };
    
    CRTVertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.texCoord = texCoords[vertexID];
    return out;
}

fragment float4 crtFragmentShader(CRTVertexOut in [[stage_in]],
                                  texture2d<float> gameTexture [[texture(0)]],
                                  constant CRTUniforms& uniforms [[buffer(0)]]) {
    
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float2 uv = in.texCoord;
    
    // 1. Barrel Distortion (CRT Curvature)
    float2 centeredUV = uv * 2.0 - 1.0;
    float offset = dot(centeredUV, centeredUV);
    float activeCurvature = mix(uniforms.curvatureStrength, 0.0, uniforms.normalizedAngle);
    float2 curvedUV = centeredUV + centeredUV * offset * activeCurvature;
    uv = curvedUV * 0.5 + 0.5;
    
    // Transparent outside the curved area so the underlying console shows
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        return float4(0.0, 0.0, 0.0, 0.0);
    }
    
    // 2. Power-On Flash
    if (uniforms.powerOnProgress < 1.0) {
        float progress = uniforms.powerOnProgress;
        float height = mix(0.01, 1.0, progress); 
        float width = mix(0.05, 1.0, progress);
        
        float distY = abs(uv.y - 0.5) * 2.0;
        float distX = abs(uv.x - 0.5) * 2.0;
        
        if (distY > height || distX > width) {
            return float4(0.0, 0.0, 0.0, 1.0);
        }
        
        if (progress < 0.5) {
            return float4(1.0, 1.0, 1.0, 1.0);
        }
    }
    
    // 4. Chromatic Aberration
    float rOffset = uniforms.chromaticAberrationOffset * activeCurvature;
    float bOffset = -uniforms.chromaticAberrationOffset * activeCurvature;
    float r = gameTexture.sample(textureSampler, uv + float2(rOffset, 0.0)).r;
    float g = gameTexture.sample(textureSampler, uv).g;
    float b = gameTexture.sample(textureSampler, uv + float2(bOffset, 0.0)).b;
    float3 color = float3(r, g, b);
    
    // 5. Phosphor Glow
    float3 glow = float3(0.0);
    glow += gameTexture.sample(textureSampler, uv + float2(0.002, 0.002)).rgb;
    glow += gameTexture.sample(textureSampler, uv + float2(-0.002, -0.002)).rgb;
    glow += gameTexture.sample(textureSampler, uv + float2(0.002, -0.002)).rgb;
    glow += gameTexture.sample(textureSampler, uv + float2(-0.002, 0.002)).rgb;
    glow *= 0.25;
    color = mix(color, glow, uniforms.glowIntensity);
    
    // 3. Scanlines
    float scanlineY = uv.y * uniforms.resolution.y * uniforms.scanlineDensity;
    float scanline = sin(scanlineY * 3.14159) * 0.15;
    color -= scanline;
    
    // 6. Vignette
    float vignette = 1.0 - smoothstep(0.5, 1.5, length(centeredUV));
    color *= vignette;
    
    // Return fully opaque screen pixels
    return float4(color, 1.0);
}
