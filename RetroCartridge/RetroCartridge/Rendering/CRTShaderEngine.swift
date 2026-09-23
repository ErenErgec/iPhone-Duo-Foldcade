// CRTShaderEngine.swift
// RetroCartridge
//
// Rendering engine that manages Metal setup, offscreen target, and shader uniforms.

import Foundation
import MetalKit
import simd

/// Uniforms passed to the CRT fragment shader. Mirrors the Metal struct exactly.
struct CRTUniforms {
    var resolution: simd_float2
    var hingeAngle: Float
    var normalizedAngle: Float
    var time: Float
    var scanlineDensity: Float
    var curvatureStrength: Float
    var chromaticAberrationOffset: Float
    var glowIntensity: Float
    var powerOnProgress: Float
}

/// Core renderer for the CRT overlay effect
class CRTShaderEngine: NSObject, MTKViewDelegate {
    
    /// The offscreen game texture that serves as the shader's input
    var gameTexture: MTLTexture?
    
    /// The device's hinge angle (0-180), updated by HingeEngine
    var hingeAngle: Float = 180.0
    
    /// Progress of the power-on animation (0-1)
    var powerOnProgress: Float = 1.0
    
    /// Provides adaptive frame rate for performance and thermal management
    var preferredFrameRate: Int = 60
    
    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var renderPipelineState: MTLRenderPipelineState?
    
    private var uniforms: CRTUniforms
    private var startTime: TimeInterval
    
    override init() {
        self.device = MTLCreateSystemDefaultDevice()
        self.startTime = Date().timeIntervalSince1970
        
        self.uniforms = CRTUniforms(
            resolution: simd_float2(x: 1080, y: 1920),
            hingeAngle: 180.0,
            normalizedAngle: 1.0,
            time: 0.0,
            scanlineDensity: 1.0,
            curvatureStrength: 0.15,
            chromaticAberrationOffset: 0.005,
            glowIntensity: 0.2,
            powerOnProgress: 1.0
        )
        
        super.init()
        setupMetal()
    }
    
    private func setupMetal() {
        guard let device = device else {
            print("CRTShaderEngine: System default Metal device not found.")
            return
        }
        
        commandQueue = device.makeCommandQueue()
        
        guard let library = device.makeDefaultLibrary() else {
            print("CRTShaderEngine: Default Metal library not found.")
            return
        }
        
        guard let vertexFunction = library.makeFunction(name: "crtVertexShader"),
              let fragmentFunction = library.makeFunction(name: "crtFragmentShader") else {
            print("CRTShaderEngine: Shader functions not found in default library.")
            return
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        // Enable blending so transparent edges show the underlying layer
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        do {
            renderPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("CRTShaderEngine: Failed to create render pipeline state - \(error)")
        }
    }
    
    func createGameTexture(size: CGSize) {
        guard let device = device, size.width > 0, size.height > 0 else { return }
        
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: Int(size.width),
            height: Int(size.height),
            mipmapped: false
        )
        descriptor.usage = [.shaderRead, .renderTarget]
        descriptor.storageMode = .private
        
        gameTexture = device.makeTexture(descriptor: descriptor)
    }
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        uniforms.resolution = simd_float2(x: Float(size.width), y: Float(size.height))
        createGameTexture(size: size)
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let pipelineState = renderPipelineState,
              let commandQueue = commandQueue,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        let currentTime = Date().timeIntervalSince1970
        uniforms.time = Float(currentTime - startTime)
        uniforms.hingeAngle = hingeAngle
        uniforms.normalizedAngle = max(0, min(1, hingeAngle / 180.0))
        uniforms.powerOnProgress = powerOnProgress
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        if let tex = gameTexture {
            renderEncoder.setFragmentTexture(tex, index: 0)
        }
        
        renderEncoder.setFragmentBytes(&uniforms, length: MemoryLayout<CRTUniforms>.stride, index: 0)
        
        // Draw the fullscreen quad (4 vertices generated in vertex shader)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
