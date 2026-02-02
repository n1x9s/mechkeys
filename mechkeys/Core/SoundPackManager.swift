//
//  SoundPackManager.swift
//  MechKeys
//

import Foundation
import Combine

@MainActor
final class SoundPackManager: ObservableObject {
    nonisolated let objectWillChange = ObservableObjectPublisher()

    static let shared = SoundPackManager()

    @Published private(set) var availablePacks: [SoundPack] = []
    @Published private(set) var currentPack: SoundPack?

    private let fileManager = FileManager.default

    private var userSoundPacksURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("MechKeys/SoundPacks", isDirectory: true)
    }

    private init() {
        loadAvailablePacks()
    }

    func loadAvailablePacks() {
        var packs: [SoundPack] = []

        // Load built-in packs from bundle
        if let bundlePacksURL = Bundle.main.resourceURL?.appendingPathComponent("SoundPacks") {
            print("[SoundPackManager] Looking for packs in: \(bundlePacksURL.path)")
            packs.append(contentsOf: loadPacks(from: bundlePacksURL, isBuiltIn: true))
        } else {
            print("[SoundPackManager] Bundle resourceURL is nil!")
        }

        // Load user packs
        createUserSoundPacksDirectoryIfNeeded()
        packs.append(contentsOf: loadPacks(from: userSoundPacksURL, isBuiltIn: false))

        availablePacks = packs.sorted { $0.name < $1.name }
    }

    private func loadPacks(from directory: URL, isBuiltIn: Bool) -> [SoundPack] {
        var packs: [SoundPack] = []

        guard let contents = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey]
        ) else {
            return []
        }

        for url in contents {
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                continue
            }

            if let pack = loadPack(from: url, isBuiltIn: isBuiltIn) {
                packs.append(pack)
            }
        }

        return packs
    }

    private func loadPack(from url: URL, isBuiltIn: Bool) -> SoundPack? {
        let manifestURL = url.appendingPathComponent("manifest.json")

        guard let data = try? Data(contentsOf: manifestURL),
              let manifest = try? JSONDecoder().decode(SoundPackManifest.self, from: data) else {
            return nil
        }

        let id = url.lastPathComponent.lowercased().replacingOccurrences(of: " ", with: "-")

        return SoundPack(
            id: id,
            manifest: manifest,
            url: url,
            isBuiltIn: isBuiltIn
        )
    }

    func selectPack(id: String) {
        guard let pack = availablePacks.first(where: { $0.id == id }) else {
            // Fallback to first available
            if let first = availablePacks.first {
                currentPack = first
                SoundEngine.shared.loadSoundPack(first)
            }
            return
        }

        currentPack = pack
        SoundEngine.shared.loadSoundPack(pack)
    }

    func selectPack(_ pack: SoundPack) {
        currentPack = pack
        SoundEngine.shared.loadSoundPack(pack)
    }

    private func createUserSoundPacksDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: userSoundPacksURL.path) {
            try? fileManager.createDirectory(
                at: userSoundPacksURL,
                withIntermediateDirectories: true
            )
        }
    }

    func importSoundPack(from sourceURL: URL) throws {
        // Validate the pack first
        guard let _ = loadPack(from: sourceURL, isBuiltIn: false) else {
            throw SoundPackError.invalidPack
        }

        let destinationURL = userSoundPacksURL.appendingPathComponent(sourceURL.lastPathComponent)

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        loadAvailablePacks()
    }

    func deleteUserPack(_ pack: SoundPack) throws {
        guard !pack.isBuiltIn else {
            throw SoundPackError.cannotDeleteBuiltIn
        }

        try fileManager.removeItem(at: pack.url)
        loadAvailablePacks()

        if currentPack?.id == pack.id {
            if let first = availablePacks.first {
                selectPack(first)
            }
        }
    }

    func previewPack(_ pack: SoundPack) {
        // Temporarily load and play a sample
        let tempEngine = SoundEngine.shared
        tempEngine.loadSoundPack(pack)
        tempEngine.play(category: .alphanumeric, action: .keyDown)

        // Play a few more keys with slight delays
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            tempEngine.play(category: .alphanumeric, action: .keyDown)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            tempEngine.play(category: .space, action: .keyDown)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            tempEngine.play(category: .enter, action: .keyDown)
        }
    }
}

enum SoundPackError: LocalizedError {
    case invalidPack
    case cannotDeleteBuiltIn

    var errorDescription: String? {
        switch self {
        case .invalidPack:
            return "Invalid sound pack. Make sure it contains a valid manifest.json file."
        case .cannotDeleteBuiltIn:
            return "Built-in sound packs cannot be deleted."
        }
    }
}
