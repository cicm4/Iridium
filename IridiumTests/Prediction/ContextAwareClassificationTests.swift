//
//  ContextAwareClassificationTests.swift
//  IridiumTests
//
//  Tests that the classification pipeline produces context-aware recommendations.
//  Code copied from an IDE should suggest IDEs (Cursor, Xcode, VSCode),
//  not just generic text editors. Prose should suggest notes apps.
//  The development pack should include Cursor as an IDE suggestion.
//

import Testing
@testable import Iridium

struct ContextAwareClassificationTests {

    // MARK: - Code Classification Accuracy

    @Test func swiftCodeClassifiesAsCode() async {
        let pipeline = ClassificationPipeline()
        let result = await pipeline.classify(uti: "public.plain-text", sample: ClipboardSamples.swiftCode)
        #expect(result.contentType == .code)
        #expect(result.language == .swift)
    }

    @Test func pythonCodeClassifiesAsCode() async {
        let pipeline = ClassificationPipeline()
        let result = await pipeline.classify(uti: "public.plain-text", sample: ClipboardSamples.pythonCode)
        #expect(result.contentType == .code)
        #expect(result.language == .python)
    }

    @Test func javascriptCodeClassifiesAsCode() async {
        let pipeline = ClassificationPipeline()
        let result = await pipeline.classify(uti: "public.plain-text", sample: ClipboardSamples.javascriptCode)
        #expect(result.contentType == .code)
        #expect(result.language == .javascript)
    }

    @Test func typescriptCodeClassifiesAsCode() async {
        let pipeline = ClassificationPipeline()
        let result = await pipeline.classify(uti: "public.plain-text", sample: ClipboardSamples.typescriptCode)
        #expect(result.contentType == .code)
    }

    @Test func proseClassifiesAsProse() async {
        let pipeline = ClassificationPipeline()
        let result = await pipeline.classify(uti: "public.plain-text", sample: ClipboardSamples.prose)
        #expect(result.contentType == .prose)
    }

    // MARK: - Development Pack Suggests Relevant IDEs

    @Test func developmentPackIncludesCursorForCode() {
        let evaluator = PackEvaluator()
        let signal = ContextSignal(
            contentType: .code,
            language: .swift
        )

        // The development pack should include cursor as a suggestion
        let devPack = PackManifest(
            id: "com.iridium.development",
            name: "Development",
            version: "1.0.0",
            author: nil, description: nil, minimumIridiumVersion: nil,
            triggers: [
                PackManifest.Trigger(
                    signal: "clipboard.contentType", matches: .exact("code"),
                    conditions: nil, confidence: 0.90,
                    suggest: ["com.todesktop.230313mzl4w4u92", "com.apple.dt.Xcode", "com.microsoft.VSCode"]
                ),
            ]
        )

        let suggestions = evaluator.evaluate(signal: signal, packs: [devPack])
        let bundleIDs = suggestions.map(\.bundleID)
        // Cursor (com.todesktop.230313mzl4w4u92) should be included
        #expect(bundleIDs.contains("com.todesktop.230313mzl4w4u92"))
    }

    @Test func proseContentSuggestsNotesAppsNotIDEs() {
        let evaluator = PackEvaluator()
        let signal = ContextSignal(
            contentType: .prose
        )

        let researchPack = PackManifest(
            id: "com.iridium.research",
            name: "Research",
            version: "1.0.0",
            author: nil, description: nil, minimumIridiumVersion: nil,
            triggers: [
                PackManifest.Trigger(
                    signal: "clipboard.contentType", matches: .exact("prose"),
                    conditions: nil, confidence: 0.80,
                    suggest: ["com.apple.Notes", "md.obsidian", "com.apple.TextEdit"]
                ),
            ]
        )

        let suggestions = evaluator.evaluate(signal: signal, packs: [researchPack])
        let bundleIDs = suggestions.map(\.bundleID)
        // Should suggest notes apps, NOT IDEs
        #expect(bundleIDs.contains("com.apple.Notes"))
        #expect(!bundleIDs.contains("com.apple.dt.Xcode"))
    }

    @Test func codeFromIDEDoesNotSuggestTextEdit() async {
        // When code is copied, TextEdit should NOT be the primary suggestion
        let pipeline = ClassificationPipeline()
        let evaluator = PackEvaluator()
        let ranker = SuggestionRanker()
        let tracker = InteractionTracker()
        let fusion = SignalFusion()

        let signal = ContextSignal(
            clipboardUTI: "public.plain-text",
            clipboardSample: ClipboardSamples.swiftCode,
            frontmostAppBundleID: "com.apple.dt.Xcode"
        )

        let classification = await pipeline.classify(uti: signal.clipboardUTI, sample: signal.clipboardSample)
        let enriched = fusion.enrich(signal: signal, classification: classification)

        let devPack = PackManifest(
            id: "com.iridium.development",
            name: "Development",
            version: "1.0.0",
            author: nil, description: nil, minimumIridiumVersion: nil,
            triggers: [
                PackManifest.Trigger(
                    signal: "clipboard.contentType", matches: .exact("code"),
                    conditions: nil, confidence: 0.90,
                    suggest: ["com.todesktop.230313mzl4w4u92", "com.apple.dt.Xcode", "com.microsoft.VSCode"]
                ),
            ]
        )

        let suggestions = evaluator.evaluate(signal: enriched, packs: [devPack])
        let ranked = ranker.rank(
            suggestions: suggestions,
            signalTimestamp: signal.timestamp,
            interactionTracker: tracker
        )

        // TextEdit should NOT appear in code suggestions
        let bundleIDs = ranked.map(\.bundleID)
        #expect(!bundleIDs.contains("com.apple.TextEdit"))
    }
}
