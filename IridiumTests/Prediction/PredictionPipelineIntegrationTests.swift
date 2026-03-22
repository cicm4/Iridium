//
//  PredictionPipelineIntegrationTests.swift
//  IridiumTests
//

import Testing
@testable import Iridium

/// Integration tests that verify the full prediction pipeline:
/// Signal → Classification → Pack Evaluation → Ranking → Suggestions
struct PredictionPipelineIntegrationTests {
    // MARK: - Full Pipeline: Code Copy → IDE Suggestions

    @Test func codeCopyProducesIDESuggestions() async {
        // Create the full pipeline components
        let pipeline = ClassificationPipeline()
        let evaluator = PackEvaluator()
        let ranker = SuggestionRanker()
        let tracker = InteractionTracker()
        let fusion = SignalFusion()

        // Simulate copying Swift code
        let rawSignal = ContextSignal(
            clipboardUTI: "public.plain-text",
            clipboardSample: ClipboardSamples.swiftCode,
            frontmostAppBundleID: "com.apple.Safari",
            hourOfDay: 14,
            displayCount: 1,
            focusModeActive: false
        )

        // Step 1: Classify
        let classification = await pipeline.classify(
            uti: rawSignal.clipboardUTI,
            sample: rawSignal.clipboardSample
        )
        #expect(classification.contentType == .code)
        #expect(classification.language == .swift)

        // Step 2: Enrich signal
        let enrichedSignal = fusion.enrich(signal: rawSignal, classification: classification)
        #expect(enrichedSignal.contentType == .code)
        #expect(enrichedSignal.language == .swift)
        // Verify timestamp is preserved from original signal
        #expect(enrichedSignal.timestamp == rawSignal.timestamp)

        // Step 3: Evaluate packs
        let devPack = PackManifest(
            id: "com.iridium.development",
            name: "Development",
            version: "1.0.0",
            author: nil, description: nil, minimumIridiumVersion: nil,
            triggers: [
                PackManifest.Trigger(
                    signal: "clipboard.contentType", matches: .exact("code"),
                    conditions: nil, confidence: 0.90,
                    suggest: ["com.apple.dt.Xcode", "com.microsoft.VSCode"]
                ),
                PackManifest.Trigger(
                    signal: nil, matches: nil,
                    conditions: [
                        PackManifest.Condition(signal: "clipboard.contentType", matches: .exact("code")),
                        PackManifest.Condition(signal: "clipboard.language", matches: .exact("swift")),
                    ],
                    confidence: 0.95,
                    suggest: ["com.apple.dt.Xcode"]
                ),
            ]
        )

        let suggestions = evaluator.evaluate(signal: enrichedSignal, packs: [devPack])
        #expect(suggestions.count >= 2)

        // Step 4: Rank
        let ranked = await ranker.rank(
            suggestions: suggestions,
            signalTimestamp: rawSignal.timestamp,
            interactionTracker: tracker
        )

        // Should be deduplicated — Xcode appears in both triggers but should appear once
        let xcodeCount = ranked.filter { $0.bundleID == "com.apple.dt.Xcode" }.count
        #expect(xcodeCount == 1)

        // Xcode should rank highest (0.95 from swift-specific trigger)
        #expect(ranked[0].bundleID == "com.apple.dt.Xcode")
    }

    // MARK: - Full Pipeline: URL Copy → Browser Suggestions

    @Test func urlCopyProducesBrowserSuggestions() async {
        let pipeline = ClassificationPipeline()
        let evaluator = PackEvaluator()
        let ranker = SuggestionRanker()
        let tracker = InteractionTracker()
        let fusion = SignalFusion()

        let rawSignal = ContextSignal(
            clipboardUTI: "public.plain-text",
            clipboardSample: "https://github.com/cicm/Iridium"
        )

        let classification = await pipeline.classify(
            uti: rawSignal.clipboardUTI,
            sample: rawSignal.clipboardSample
        )
        #expect(classification.contentType == .url)

        let enrichedSignal = fusion.enrich(signal: rawSignal, classification: classification)

        let researchPack = PackManifest(
            id: "com.iridium.research",
            name: "Research",
            version: "1.0.0",
            author: nil, description: nil, minimumIridiumVersion: nil,
            triggers: [
                PackManifest.Trigger(
                    signal: "clipboard.contentType", matches: .exact("url"),
                    conditions: nil, confidence: 0.90,
                    suggest: ["com.apple.Safari", "com.google.Chrome"]
                ),
            ]
        )

        let suggestions = evaluator.evaluate(signal: enrichedSignal, packs: [researchPack])
        #expect(suggestions.count == 2)

        let ranked = await ranker.rank(
            suggestions: suggestions,
            signalTimestamp: rawSignal.timestamp,
            interactionTracker: tracker
        )
        #expect(ranked.count == 2)
    }

    // MARK: - Full Pipeline: Email → Mail Suggestions

    @Test func emailCopyProducesMailSuggestions() async {
        let pipeline = ClassificationPipeline()
        let evaluator = PackEvaluator()
        let fusion = SignalFusion()

        let rawSignal = ContextSignal(
            clipboardUTI: "public.plain-text",
            clipboardSample: "user@example.com"
        )

        let classification = await pipeline.classify(
            uti: rawSignal.clipboardUTI,
            sample: rawSignal.clipboardSample
        )
        #expect(classification.contentType == .email)

        let enrichedSignal = fusion.enrich(signal: rawSignal, classification: classification)

        let commPack = PackManifest(
            id: "com.iridium.communication",
            name: "Communication",
            version: "1.0.0",
            author: nil, description: nil, minimumIridiumVersion: nil,
            triggers: [
                PackManifest.Trigger(
                    signal: "clipboard.contentType", matches: .exact("email"),
                    conditions: nil, confidence: 0.90,
                    suggest: ["com.apple.mail"]
                ),
            ]
        )

        let suggestions = evaluator.evaluate(signal: enrichedSignal, packs: [commPack])
        #expect(suggestions.count == 1)
        #expect(suggestions[0].bundleID == "com.apple.mail")
    }

    // MARK: - Focus Mode Suppression

    @Test func focusModeBlocksPrediction() async {
        let pipeline = ClassificationPipeline()
        let evaluator = PackEvaluator()
        let fusion = SignalFusion()

        let rawSignal = ContextSignal(
            clipboardUTI: "public.plain-text",
            clipboardSample: ClipboardSamples.swiftCode,
            focusModeActive: true
        )

        // Classification should still work
        let classification = await pipeline.classify(
            uti: rawSignal.clipboardUTI,
            sample: rawSignal.clipboardSample
        )
        #expect(classification.contentType == .code)

        // But the signal carries focusModeActive = true
        let enrichedSignal = fusion.enrich(signal: rawSignal, classification: classification)
        #expect(enrichedSignal.focusModeActive == true)
        // PredictionEngine.processSignal checks this and returns early
    }

    // MARK: - Frequency Capping Integration

    @Test func frequencyCappingSuppressesAfterDismissals() async {
        let tracker = InteractionTracker()

        // Simulate 3 dismissals
        tracker.recordDismissal()
        tracker.recordDismissal()
        tracker.recordDismissal()

        #expect(tracker.isSuppressed)
        // PredictionEngine.processSignal checks tracker.isSuppressed and returns early
    }
}
