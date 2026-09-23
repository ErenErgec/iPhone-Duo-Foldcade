//
//  AudioManager.swift
//  RetroCartridge
//
//  Synthesizes 8-bit sounds using AVAudioEngine for low-latency game sounds.
//

import AVFoundation
import Observation
import os

/// Available game sounds.
enum GameSound {
    case lineComplete
    case collision
    case powerUp
    case gameOver
    case levelUp
}

/// Thread-safe synthesizer running on the realtime CoreAudio thread.
/// Completely nonisolated from any actor.
final class ToneGenerator: @unchecked Sendable {
    private var lock = os_unfair_lock()
    
    private var currentPhase: Double = 0.0
    private var activeFrequency: Double = 0.0
    private var activeAmplitude: Double = 0.0
    private var isSquareWave: Bool = true
    private var framesRemaining: Int = 0
    private let sampleRate: Double = 44100.0
    
    var isMuted: Bool = false
    
    func setTone(frequency: Double, durationMs: Int, isSquare: Bool) {
        os_unfair_lock_lock(&lock)
        self.activeFrequency = frequency
        self.activeAmplitude = 0.35
        self.isSquareWave = isSquare
        self.framesRemaining = Int((Double(durationMs) / 1000.0) * sampleRate)
        self.currentPhase = 0.0
        os_unfair_lock_unlock(&lock)
    }
    
    func render(frameCount: AVAudioFrameCount, audioBufferList: UnsafeMutablePointer<AudioBufferList>) -> OSStatus {
        let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
        
        os_unfair_lock_lock(&lock)
        let muted = self.isMuted
        let freq = self.activeFrequency
        let amp = self.activeAmplitude
        let square = self.isSquareWave
        var rem = self.framesRemaining
        var phase = self.currentPhase
        let sRate = self.sampleRate
        os_unfair_lock_unlock(&lock)
        
        for frame in 0..<Int(frameCount) {
            var value: Float = 0
            if rem > 0 {
                let phaseIncrement = (freq * 2.0 * .pi) / sRate
                phase += phaseIncrement
                if phase > 2.0 * .pi {
                    phase -= 2.0 * .pi
                }
                
                if square {
                    value = phase < .pi ? Float(amp) : Float(-amp)
                } else {
                    value = Float(sin(phase) * amp)
                }
                
                rem -= 1
            }
            
            for buffer in ablPointer {
                let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                buf[frame] = muted ? 0 : value
            }
        }
        
        os_unfair_lock_lock(&lock)
        self.framesRemaining = rem
        self.currentPhase = phase
        if rem == 0 {
            self.activeAmplitude = 0.0
        }
        os_unfair_lock_unlock(&lock)
        
        return noErr
    }
}

/// Standalone nonisolated factory for the AVAudioSourceNode so no actor context is captured.
private nonisolated func makeSourceNode(generator: ToneGenerator) -> AVAudioSourceNode {
    return AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
        return generator.render(frameCount: frameCount, audioBufferList: audioBufferList)
    }
}

@Observable
final class AudioManager: @unchecked Sendable {
    
    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private let generator = ToneGenerator()
    private var isEngineStarted = false
    
    var isMuted: Bool {
        get { generator.isMuted }
        set { generator.isMuted = newValue }
    }
    
    init() {
        setupAudio()
    }
    
    private func setupAudio() {
        let sampleRate: Double = 44100.0
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            return
        }
        
        let node = makeSourceNode(generator: generator)
        self.sourceNode = node
        
        engine.attach(node)
        try? engine.connectNode(node, to: engine.mainMixerNode, format: format)
        
        configureAudioSession()
        
        do {
            try engine.start()
            isEngineStarted = true
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient, mode: .default)
            try session.setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }
    
    private func playTone(frequency: Double, durationMs: Int, isSquare: Bool = true) {
        if !isEngineStarted {
            try? engine.start()
            isEngineStarted = true
        }
        generator.setTone(frequency: frequency, durationMs: durationMs, isSquare: isSquare)
    }
    
    func playStartupChime() {
        guard !isMuted else { return }
        // Ascending C - E - G arpeggio (100ms each)
        playTone(frequency: 261.63, durationMs: 100, isSquare: true)
        
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            self.playTone(frequency: 329.63, durationMs: 100, isSquare: true)
            try? await Task.sleep(nanoseconds: 100_000_000)
            self.playTone(frequency: 392.00, durationMs: 100, isSquare: true)
        }
    }
    
    func playCartridgeClick() {
        guard !isMuted else { return }
        playTone(frequency: 100.0, durationMs: 50, isSquare: true)
    }
    
    func playHingeSnap() {
        guard !isMuted else { return }
        playTone(frequency: 150.0, durationMs: 30, isSquare: false)
    }
    
    func playGameSound(_ sound: GameSound) {
        guard !isMuted else { return }
        switch sound {
        case .lineComplete:
            playTone(frequency: 880.0, durationMs: 150, isSquare: true)
        case .collision:
            playTone(frequency: 110.0, durationMs: 100, isSquare: true)
        case .powerUp:
            playTone(frequency: 440.0, durationMs: 200, isSquare: false)
        case .gameOver:
            playTone(frequency: 55.0, durationMs: 500, isSquare: true)
        case .levelUp:
            playTone(frequency: 523.25, durationMs: 300, isSquare: false)
        }
    }
}
