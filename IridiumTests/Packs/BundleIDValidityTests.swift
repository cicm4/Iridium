//
//  BundleIDValidityTests.swift
//  IridiumTests
//

import Foundation
import Testing
@testable import Iridium

struct BundleIDValidityTests {
    @Test func researchPackPagesIDIsCorrect() {
        // Load research pack from bundle, verify com.apple.iWork.Pages present
        // We can't load from Bundle.main in tests, so parse the JSON directly
        let packs = loadBuiltInPackManifests()
        let research = packs.first { $0.id == "com.iridium.research" }
        let allBundleIDs = research?.triggers.flatMap(\.suggest) ?? []
        #expect(allBundleIDs.contains("com.apple.iWork.Pages"))
        #expect(!allBundleIDs.contains("com.apple.Pages"))
    }

    @Test func developmentPackWebStormIDIsCorrect() {
        let packs = loadBuiltInPackManifests()
        let dev = packs.first { $0.id == "com.iridium.development" }
        let allBundleIDs = dev?.triggers.flatMap(\.suggest) ?? []
        #expect(allBundleIDs.contains("com.jetbrains.WebStorm"))
        #expect(!allBundleIDs.contains("com.webstorm"))
    }

    // Helper to load pack manifests from the BuiltIn directory
    private func loadBuiltInPackManifests() -> [PackManifest] {
        let builtInDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // BundleIDValidityTests.swift -> Packs/
            .deletingLastPathComponent() // Packs/ -> IridiumTests/
            .deletingLastPathComponent() // IridiumTests/ -> project root
            .appendingPathComponent("Iridium/Packs/BuiltIn")

        guard let files = try? FileManager.default.contentsOfDirectory(at: builtInDir, includingPropertiesForKeys: nil) else {
            return []
        }

        return files.compactMap { url -> PackManifest? in
            guard url.pathExtension == "iridiumpack" else { return nil }
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? JSONDecoder().decode(PackManifest.self, from: data)
        }
    }
}
