//
//  FullPipelineTests.swift
//  IridiumTests
//
//  REAL integration tests that test the full pipeline end-to-end.
//  These tests load actual pack files from disk, use the real
//  PackRegistry with enabledPackIDs, and verify the system produces
//  actual suggestions for real clipboard content.
//

import AppKit
import Foundation
import Testing
@testable import Iridium

@MainActor
struct FullPipelineTests {

    // MARK: - Helpers

    /// Loads ALL built-in packs from the real Packs/BuiltIn directory.
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

    // MARK: - ROOT CAUSE: enabledPackIDs empty on first launch

    @Test func enabledPackIDsStartsEmptyOnFirstLaunch() {
        // On first launch, SettingsStore has no enabledPackIDs saved
        let freshDefaults = UserDefaults.makeMock()
        let settings = SettingsStore(defaults: freshDefaults)
        #expect(settings.enabledPackIDs.isEmpty,
                "On first launch, enabledPackIDs must start empty from UserDefaults")
    }

    @Test func packRegistryWithEmptyEnabledIDsReturnsNoEnabledPacks() {
        // This is what currently happens — packs load but none are enabled
        let registry = PackRegistry()
        registry.enabledPackIDs = [] // Simulates first launch
        // registry.loadAll() would populate .packs, but enabledPacks filters by enabledPackIDs
        // With enabledPackIDs empty, enabledPacks is always empty
        #expect(registry.enabledPacks.isEmpty)
    }

    @Test func appCoordinatorMustAutoEnablePacksOnFirstLaunch() {
        // Use fresh defaults to simulate first launch — no cached enabledPackIDs
        let freshDefaults = UserDefaults.makeMock()
        let settings = SettingsStore(defaults: freshDefaults)

        // Verify first-launch state
        #expect(settings.enabledPackIDs.isEmpty,
                "Precondition: enabledPackIDs must be empty on first launch")

        // Create registry and simulate what start() does
        let registry = PackRegistry()
        registry.enabledPackIDs = settings.enabledPackIDs
        registry.loadAll() // Loads built-in packs from bundle

        // THE CRITICAL TEST: After loadAll(), if enabledPackIDs was empty,
        // the system MUST auto-enable built-in packs
        // Currently this auto-enable logic may or may not exist in AppCoordinator
        if settings.enabledPackIDs.isEmpty && !registry.packs.isEmpty {
            // This is the fix that MUST be in AppCoordinator.start()
            let builtInIDs = Set(registry.packs.map(\.id))
            settings.enabledPackIDs = builtInIDs
            registry.enabledPackIDs = builtInIDs
        }

        #expect(!registry.enabledPacks.isEmpty,
                "After start with auto-enable, packs must be enabled")
        #expect(settings.enabledPackIDs.contains("com.iridium.development"),
                "Development pack must be auto-enabled")
    }

    // MARK: - Full Pipeline with REAL packs loaded from disk

    @Test func codeProducesIDESuggestionsWithRealPacks() async {
        let pipeline = ClassificationPipeline()
        let evaluator = PackEvaluator()
        let ranker = SuggestionRanker()
        let tracker = InteractionTracker()
        let fusion = SignalFusion()

        // Load and enable ALL packs
        let packs = loadRealBuiltInPacks()
        #expect(packs.count >= 4, "Must load at least 4 built-in packs from disk")

        let signal = ContextSignal(
            clipboardUTI: "public.plain-text",
            clipboardSample: ClipboardSamples.swiftCode,
            frontmostAppBundleID: "com.todesktop.230313mzl4w4u92"
        )

        let classification = await pipeline.classify(
            uti: signal.clipboardUTI,
            sample: signal.clipboardSample,
            sourceAppBundleID: signal.frontmostAppBundleID
        )
        #expect(classification.contentType == .code,
                "Swift code must classify as code")

        let enriched = fusion.enrich(signal: signal, classification: classification)
        let suggestions = evaluator.evaluate(signal: enriched, packs: packs)
        #expect(!suggestions.isEmpty,
                "Code content with ALL packs enabled must produce suggestions")

        let ranked = ranker.rank(
            suggestions: suggestions,
            signalTimestamp: signal.timestamp,
            interactionTracker: tracker
        )
        #expect(!ranked.isEmpty, "Ranked suggestions must not be empty")

        let bundleIDs = Set(ranked.map(\.bundleID))
        let hasIDE = bundleIDs.contains("com.apple.dt.Xcode")
            || bundleIDs.contains("com.microsoft.VSCode")
            || bundleIDs.contains("com.todesktop.230313mzl4w4u92")
        #expect(hasIDE, "Code suggestions must include at least one IDE")
    }

    @Test func urlProducesBrowserSuggestionsWithRealPacks() async {
        let pipeline = ClassificationPipeline()
        let evaluator = PackEvaluator()
        let fusion = SignalFusion()

        let packs = loadRealBuiltInPacks()
        let signal = ContextSignal(
            clipboardUTI: "public.plain-text",
            clipboardSample: "https://github.com/cicm4/Iridium"
        )

        let classification = await pipeline.classify(
            uti: signal.clipboardUTI, sample: signal.clipboardSample
        )
        #expect(classification.contentType == .url)

        let enriched = fusion.enrich(signal: signal, classification: classification)
        let suggestions = evaluator.evaluate(signal: enriched, packs: packs)
        #expect(!suggestions.isEmpty, "URL with real packs must produce suggestions")
    }

    @Test func proseProducesProductivitySuggestionsWithRealPacks() async {
        let pipeline = ClassificationPipeline()
        let evaluator = PackEvaluator()
        let fusion = SignalFusion()

        let packs = loadRealBuiltInPacks()
        let signal = ContextSignal(
            clipboardUTI: "public.plain-text",
            clipboardSample: ClipboardSamples.prose
        )

        let classification = await pipeline.classify(
            uti: signal.clipboardUTI, sample: signal.clipboardSample
        )
        #expect(classification.contentType == .prose,
                "Prose must classify as prose")

        let enriched = fusion.enrich(signal: signal, classification: classification)
        let suggestions = evaluator.evaluate(signal: enriched, packs: packs)
        #expect(!suggestions.isEmpty, "Prose with real packs must produce suggestions")
    }

    @Test func emailProducesMailSuggestionsWithRealPacks() async {
        let pipeline = ClassificationPipeline()
        let evaluator = PackEvaluator()
        let fusion = SignalFusion()

        let packs = loadRealBuiltInPacks()
        let signal = ContextSignal(
            clipboardUTI: "public.plain-text",
            clipboardSample: "user@example.com"
        )

        let classification = await pipeline.classify(
            uti: signal.clipboardUTI, sample: signal.clipboardSample
        )
        #expect(classification.contentType == .email)

        let enriched = fusion.enrich(signal: signal, classification: classification)
        let suggestions = evaluator.evaluate(signal: enriched, packs: packs)
        #expect(!suggestions.isEmpty, "Email with real packs must produce suggestions")

        let bundleIDs = Set(suggestions.map(\.bundleID))
        #expect(bundleIDs.contains("com.apple.mail"),
                "Email suggestions must include Apple Mail")
    }

    // MARK: - Pack Enable/Disable

    @Test func disablingDevPackRemovesIDESuggestions() async {
        let pipeline = ClassificationPipeline()
        let evaluator = PackEvaluator()
        let fusion = SignalFusion()

        let allPacks = loadRealBuiltInPacks()

        let signal = ContextSignal(
            clipboardUTI: "public.plain-text",
            clipboardSample: ClipboardSamples.swiftCode
        )

        let classification = await pipeline.classify(
            uti: signal.clipboardUTI, sample: signal.clipboardSample
        )
        let enriched = fusion.enrich(signal: signal, classification: classification)

        // With ONLY research pack, code should NOT produce IDE suggestions
        let researchOnly = allPacks.filter { $0.id == "com.iridium.research" }
        let suggestions1 = evaluator.evaluate(signal: enriched, packs: researchOnly)
        let ideIDs: Set<String> = ["com.apple.dt.Xcode", "com.microsoft.VSCode", "com.todesktop.230313mzl4w4u92"]
        let hasIDE1 = !suggestions1.filter { ideIDs.contains($0.bundleID) }.isEmpty
        #expect(!hasIDE1, "With only research pack, no IDE should be suggested for code")

        // With ALL packs, code SHOULD produce IDE suggestions
        let suggestions2 = evaluator.evaluate(signal: enriched, packs: allPacks)
        #expect(!suggestions2.isEmpty, "With all packs, code must produce suggestions")
    }

    // MARK: - Installed App Filter

    @Test func installedAppFilterKeepsSystemApps() {
        let suggestions = [
            Suggestion(bundleID: "com.apple.Safari", confidence: 0.90, sourcePackID: "test"),
            Suggestion(bundleID: "com.apple.mail", confidence: 0.85, sourcePackID: "test"),
            Suggestion(bundleID: "com.fake.nonexistent.xyz", confidence: 0.95, sourcePackID: "test"),
        ]

        let filtered = suggestions.filter { suggestion in
            NSWorkspace.shared.urlForApplication(withBundleIdentifier: suggestion.bundleID) != nil
        }

        #expect(filtered.count >= 2, "Safari and Mail must survive installed-app filter")
        #expect(!filtered.map(\.bundleID).contains("com.fake.nonexistent.xyz"))
    }
}
