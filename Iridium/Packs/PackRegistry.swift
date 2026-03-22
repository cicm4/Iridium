//
//  PackRegistry.swift
//  Iridium
//

import Foundation
import Observation
import OSLog

@Observable
final class PackRegistry {
    private(set) var packs: [PackManifest] = []
    private let loader = PackLoader()

    var enabledPacks: [PackManifest] {
        packs.filter { enabledPackIDs.contains($0.id) }
    }

    var enabledPackIDs: Set<String> = []

    func loadAll() {
        let builtIn = loader.loadBuiltInPacks()
        let user = loader.loadUserPacks()
        packs = builtIn + user
        Logger.packs.info("Loaded \(self.packs.count) packs (\(builtIn.count) built-in, \(user.count) user)")
    }

    func installPack(from url: URL) -> Bool {
        guard let manifest = loader.loadPack(from: url) else { return false }

        // Don't allow duplicate IDs
        guard !packs.contains(where: { $0.id == manifest.id }) else {
            Logger.packs.warning("Pack with ID '\(manifest.id)' already installed")
            return false
        }

        packs.append(manifest)
        enabledPackIDs.insert(manifest.id)
        return true
    }

    func removePack(id: String) {
        packs.removeAll { $0.id == id }
        enabledPackIDs.remove(id)
    }

    func togglePack(id: String, enabled: Bool) {
        if enabled {
            enabledPackIDs.insert(id)
        } else {
            enabledPackIDs.remove(id)
        }
    }
}
