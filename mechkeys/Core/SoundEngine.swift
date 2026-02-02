//
//  SoundEngine.swift
//  MechKeys
//

import Foundation
import AVFoundation

final class SoundEngine: @unchecked Sendable {
    static let shared = SoundEngine()

    private let engine = AVAudioEngine()
    private var playerNodes: [AVAudioPlayerNode] = []
    private var currentNodeIndex = 0
    private let nodeCount = 16

    private var bufferCache: [KeyCategory: [KeyAction: [AVAudioPCMBuffer]]] = [:]
    private var lastPlayedIndex: [KeyCategory: [KeyAction: Int]] = [:]

    private let lock = NSLock()

    private var baseVolume: Float = 0.75
    private var basePitch: Float = 1.0
    private var variability: Float = 0.3
    private var keyUpEnabled: Bool = true

    private init() {
        setupEngine()
    }

    private func setupEngine() {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)

        for _ in 0..<nodeCount {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            playerNodes.append(node)
        }

        do {
            try engine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    func loadSoundPack(_ pack: SoundPack) {
        lock.lock()
        defer { lock.unlock() }

        print("[SoundEngine] Loading sound pack: \(pack.name) from \(pack.url.path)")

        bufferCache.removeAll()
        lastPlayedIndex.removeAll()

        for category in KeyCategory.allCases {
            bufferCache[category] = [:]
            lastPlayedIndex[category] = [:]

            for action in KeyAction.allCases {
                let urls = pack.soundFileURLs(for: category, action: action)
                var buffers: [AVAudioPCMBuffer] = []

                for url in urls {
                    if let buffer = loadBuffer(from: url) {
                        buffers.append(buffer)
                    }
                }

                // Fallback: use alphanumeric sounds if category is empty
                if buffers.isEmpty && category != .alphanumeric {
                    let fallbackURLs = pack.soundFileURLs(for: .alphanumeric, action: action)
                    for url in fallbackURLs {
                        if let buffer = loadBuffer(from: url) {
                            buffers.append(buffer)
                        }
                    }
                }

                bufferCache[category]?[action] = buffers
                lastPlayedIndex[category]?[action] = -1

                if !buffers.isEmpty {
                    print("[SoundEngine] Loaded \(buffers.count) buffers for \(category) \(action)")
                }
            }
        }

        print("[SoundEngine] Sound pack loaded")
    }

    private func loadBuffer(from url: URL) -> AVAudioPCMBuffer? {
        guard let audioFile = try? AVAudioFile(forReading: url) else {
            return nil
        }

        let format = audioFile.processingFormat
        let frameCount = AVAudioFrameCount(audioFile.length)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }

        do {
            try audioFile.read(into: buffer)
            return buffer
        } catch {
            return nil
        }
    }

    func play(category: KeyCategory, action: KeyAction) {
        guard action == .keyDown || keyUpEnabled else { return }

        lock.lock()

        guard let buffers = bufferCache[category]?[action],
              !buffers.isEmpty else {
            lock.unlock()
            print("[SoundEngine] No buffers for \(category) \(action)")
            return
        }

        // Select buffer (avoid repeating the same one)
        var index: Int
        if buffers.count == 1 {
            index = 0
        } else {
            let lastIndex = lastPlayedIndex[category]?[action] ?? -1
            repeat {
                index = Int.random(in: 0..<buffers.count)
            } while index == lastIndex
        }

        lastPlayedIndex[category]?[action] = index
        let buffer = buffers[index]

        let nodeIndex = currentNodeIndex % nodeCount
        currentNodeIndex += 1
        let node = playerNodes[nodeIndex]

        lock.unlock()

        // Calculate variations
        let volumeVariation = Float.random(in: -variability * 0.08...variability * 0.08)
        let pitchVariation = Float.random(in: -variability * 0.05...variability * 0.05)

        node.stop()
        node.volume = min(1.0, max(0.0, baseVolume + volumeVariation))
        node.rate = basePitch + pitchVariation
        node.scheduleBuffer(buffer, at: nil)
        node.play()
    }

    func updateSettings(volume: Float, pitch: Float, variability: Float, keyUpEnabled: Bool) {
        lock.lock()
        defer { lock.unlock() }

        self.baseVolume = volume
        self.basePitch = pitch
        self.variability = variability
        self.keyUpEnabled = keyUpEnabled
    }

    func stop() {
        for node in playerNodes {
            node.stop()
        }
    }
}
