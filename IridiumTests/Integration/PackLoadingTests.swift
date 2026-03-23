//
//  PackLoadingTests.swift
//  IridiumTests
//
//  Tests that verify pack files are valid, loadable, and functional.
//  These load REAL .iridiumpack files from disk — not hardcoded JSON.
//

import Foundation
import Testing
@testable import Iridium

struct PackLoadingTests {

    private func loadRealBuiltInPacks() -> [PackManifest] {
        let sourceDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Integration/
            .deletingLastPathComponent() // IridiumTests/
            .deletingLastPathComponent() // project root
            .appendingPathComponent("Iridium/Packs/BuiltIn")

        guard let files = try? FileManager.default.contentsOfDirectory(
            at: sourceDir, includingPropertiesForKeys: nil
        ) else {
            return []
        }

        return files.compactMap { url -> PackManifest? in
            guard url.pathExtension == "iridiumpack" else { return nil }
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? JSONDecoder().decode(PackManifest.self, from: data)
        }
    }

    // MARK: - Pack Loading

    @Test func builtInPacksLoadFromDisk() {
        let packs = loadRealBuiltInPacks()
        #expect(packs.count >= 4,
                "Must have at least 4 built-in packs (development, research, creative, communication)")

        let ids = Set(packs.map(\.id))
        #expect(ids.contains("com.iridium.development"), "Development pack missing")
        #expect(ids.contains("com.iridium.research"), "Research pack missing")
        #expect(ids.contains("com.iridium.creative"), "Creative pack missing")
        #expect(ids.contains("com.iridium.communication"), "Communication pack missing")
    }

    @Test func allPacksHaveValidTriggers() {
        let packs = loadRealBuiltInPacks()
        for pack in packs {
            #expect(!pack.triggers.isEmpty, "Pack \(pack.id) has no triggers")
            for trigger in pack.triggers {
                #expect(!trigger.suggest.isEmpty,
                        "Trigger in \(pack.id) has empty suggest list")
                // Every confidence must be 0-1
                #expect(trigger.confidence >= 0.0 && trigger.confidence <= 1.0,
                        "Trigger in \(pack.id) has invalid confidence: \(trigger.confidence)")
            }
        }
    }

    @Test func allPackTriggersUseKnownSignalNames() {
        let knownSignals: Set<String> = [
            "clipboard.contentType", "clipboard.language",
            "app.frontmost", "time.hourOfDay", "display.count"
        ]
        let packs = loadRealBuiltInPacks()

        for pack in packs {
            for trigger in pack.triggers {
                // Check single-signal form
                if let signal = trigger.signal {
                    #expect(knownSignals.contains(signal),
                            "Pack \(pack.id) uses unknown signal '\(signal)'")
                }
                // Check multi-condition form
                if let conditions = trigger.conditions {
                    for condition in conditions {
                        #expect(knownSignals.contains(condition.signal),
                                "Pack \(pack.id) uses unknown signal '\(condition.signal)' in conditions")
                    }
                }
            }
        }
    }

    @Test func developmentPackTriggersFireForCode() {
        let packs = loadRealBuiltInPacks()
        let devPack = packs.first { $0.id == "com.iridium.development" }!

        let evaluator = PackEvaluator()
        let signal = ContextSignal(contentType: .code, language: .swift)

        let suggestions = evaluator.evaluate(signal: signal, packs: [devPack])
        #expect(!suggestions.isEmpty,
                "Development pack must produce suggestions for code content type")

        let bundleIDs = Set(suggestions.map(\.bundleID))
        #expect(bundleIDs.contains("com.apple.dt.Xcode") || bundleIDs.contains("com.microsoft.VSCode"),
                "Development pack must suggest IDEs for code. Got: \(bundleIDs)")
    }

    @Test func researchPackTriggersFireForURL() {
        let packs = loadRealBuiltInPacks()
        let researchPack = packs.first { $0.id == "com.iridium.research" }!

        let evaluator = PackEvaluator()
        let signal = ContextSignal(contentType: .url)

        let suggestions = evaluator.evaluate(signal: signal, packs: [researchPack])
        #expect(!suggestions.isEmpty,
                "Research pack must produce suggestions for URL content type")

        let bundleIDs = Set(suggestions.map(\.bundleID))
        #expect(bundleIDs.contains("com.apple.Safari"),
                "Research pack must suggest Safari for URLs. Got: \(bundleIDs)")
    }

    @Test func researchPackTriggersFireForProse() {
        let packs = loadRealBuiltInPacks()
        let researchPack = packs.first { $0.id == "com.iridium.research" }!

        let evaluator = PackEvaluator()
        let signal = ContextSignal(contentType: .prose)

        let suggestions = evaluator.evaluate(signal: signal, packs: [researchPack])
        #expect(!suggestions.isEmpty,
                "Research pack must produce suggestions for prose content type")
    }

    @Test func communicationPackTriggersFireForEmail() {
        let packs = loadRealBuiltInPacks()
        let commPack = packs.first { $0.id == "com.iridium.communication" }!

        let evaluator = PackEvaluator()
        let signal = ContextSignal(contentType: .email)

        let suggestions = evaluator.evaluate(signal: signal, packs: [commPack])
        #expect(!suggestions.isEmpty,
                "Communication pack must produce suggestions for email content type")
    }
}
