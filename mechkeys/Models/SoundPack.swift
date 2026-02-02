//
//  SoundPack.swift
//  MechKeys
//

import Foundation

struct SoundPackManifest: Codable {
    let name: String
    let description: String
    let author: String
    let version: String
}

struct SoundPack: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let author: String
    let version: String
    let url: URL
    let isBuiltIn: Bool

    static func == (lhs: SoundPack, rhs: SoundPack) -> Bool {
        lhs.id == rhs.id
    }

    init(id: String, manifest: SoundPackManifest, url: URL, isBuiltIn: Bool) {
        self.id = id
        self.name = manifest.name
        self.description = manifest.description
        self.author = manifest.author
        self.version = manifest.version
        self.url = url
        self.isBuiltIn = isBuiltIn
    }

    func soundFileURLs(for category: KeyCategory, action: KeyAction) -> [URL] {
        let categoryFolder = url.appendingPathComponent(category.folderName)
        let prefix = action == .keyDown ? "keydown" : "keyup"

        var urls: [URL] = []
        let fileManager = FileManager.default

        guard let contents = try? fileManager.contentsOfDirectory(
            at: categoryFolder,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }

        for fileURL in contents {
            let filename = fileURL.lastPathComponent.lowercased()
            if filename.hasPrefix(prefix) &&
               (filename.hasSuffix(".wav") || filename.hasSuffix(".caf")) {
                urls.append(fileURL)
            }
        }

        return urls.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
}
