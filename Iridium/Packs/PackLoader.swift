//
//  PackLoader.swift
//  Iridium
//

import Foundation
import OSLog

struct PackLoader: Sendable {
    private let validator = PackValidator()

    /// Loads built-in packs from the app bundle.
    func loadBuiltInPacks() -> [PackManifest] {
        guard let bundlePath = Bundle.main.resourcePath else { return [] }
        return loadPacksFromDirectory(URL(fileURLWithPath: bundlePath))
    }

    /// Loads user-installed packs from ~/Library/Application Support/Iridium/Packs/.
    func loadUserPacks() -> [PackManifest] {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return []
        }
        let packsDir = appSupport.appendingPathComponent("Iridium/Packs", isDirectory: true)

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: packsDir, withIntermediateDirectories: true)

        return loadPacksFromDirectory(packsDir)
    }

    /// Loads a single pack from a file URL.
    func loadPack(from url: URL) -> PackManifest? {
        guard url.pathExtension == "iridiumpack" else {
            Logger.packs.warning("Skipped non-pack file: \(url.lastPathComponent)")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let manifest = try JSONDecoder().decode(PackManifest.self, from: data)
            try validator.validate(manifest)
            Logger.packs.info("Loaded pack: \(manifest.id) v\(manifest.version)")
            return manifest
        } catch {
            Logger.packs.error("Failed to load pack \(url.lastPathComponent): \(error.localizedDescription)")
            return nil
        }
    }

    private func loadPacksFromDirectory(_ directory: URL) -> [PackManifest] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }

        return contents.compactMap { loadPack(from: $0) }
    }
}
