//
//  EndToEndSuggestionTests.swift
//  IridiumTests
//
//  End-to-end tests that simulate EXACTLY what PredictionEngine.processSignal does,
//  including the installed-app filter, to find why the user sees prose suggestions
//  (Word, Pages, Notes) instead of IDE suggestions when copying code.
//

import AppKit
import Foundation
import Testing
@testable import Iridium

@MainActor
struct EndToEndSuggestionTests {

    private func loadRealBuiltInPacks() -> [PackManifest] {
        let sourceDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Iridium/Packs/BuiltIn")
        guard let files = try? FileManager.default.contentsOfDirectory(at: sourceDir, includingPropertiesForKeys: nil) else { return [] }
        return files.compactMap { url -> PackManifest? in
            guard url.pathExtension == "iridiumpack" else { return nil }
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? JSONDecoder().decode(PackManifest.self, from: data)
        }
    }

    // MARK: - Diagnose the exact failure: classification, pack eval, or installed filter?

    @Test func diagnoseWhyCodeShowsProseResults() async {
        let pipeline = ClassificationPipeline()
        let evaluator = PackEvaluator()
        let ranker = SuggestionRanker()
        let tracker = InteractionTracker()
        let fusion = SignalFusion()
        let allPacks = loadRealBuiltInPacks()

        // Simulate copying Swift code from Cursor
        let signal = ContextSignal(
            clipboardUTI: "public.plain-text",
            clipboardSample: ClipboardSamples.swiftCode,
            frontmostAppBundleID: "com.todesktop.230313mzl4w4u92"
        )

        // Step 1: Classification
        let classification = await pipeline.classify(
            uti: signal.clipboardUTI,
            sample: signal.clipboardSample,
            sourceAppBundleID: signal.frontmostAppBundleID
        )
        #expect(classification.contentType == .code,
                "STEP 1 FAILED: Classification returned \(classification.contentType.rawValue) instead of code")

        // Step 2: Enrichment
        let enriched = fusion.enrich(signal: signal, classification: classification)
        #expect(enriched.contentType == .code, "STEP 2 FAILED: Enriched signal lost code type")

        // Step 3: Pack evaluation — which packs fire?
        let suggestions = evaluator.evaluate(signal: enriched, packs: allPacks)
        #expect(!suggestions.isEmpty, "STEP 3 FAILED: No packs fired at all")

        let devSuggestions = suggestions.filter { $0.sourcePackID == "com.iridium.development" }
        let researchSuggestions = suggestions.filter { $0.sourcePackID == "com.iridium.research" }
        #expect(!devSuggestions.isEmpty, "STEP 3 FAILED: Development pack did not fire for code")
        #expect(researchSuggestions.isEmpty,
                "STEP 3 BUG: Research pack ALSO fired for code — prose trigger should not match code content")

        // Step 4: Ranking
        let ranked = ranker.rank(
            suggestions: suggestions,
            signalTimestamp: signal.timestamp,
            interactionTracker: tracker
        )
        #expect(!ranked.isEmpty, "STEP 4 FAILED: Ranking eliminated all suggestions")

        // Step 5: Installed app filter — THIS IS THE LIKELY CULPRIT
        let installed = ranked.filter { suggestion in
            NSWorkspace.shared.urlForApplication(withBundleIdentifier: suggestion.bundleID) != nil
        }

        // Log which IDs survived and which were filtered
        let survivedIDs = installed.map(\.bundleID)
        let filteredIDs = ranked.filter { suggestion in
            NSWorkspace.shared.urlForApplication(withBundleIdentifier: suggestion.bundleID) == nil
        }.map(\.bundleID)

        // The critical assertion: at least one IDE must survive the filter
        let ideIDs: Set<String> = ["com.todesktop.230313mzl4w4u92", "com.apple.dt.Xcode", "com.microsoft.VSCode"]
        let survivingIDEs = survivedIDs.filter { ideIDs.contains($0) }

        #expect(!survivingIDEs.isEmpty,
                "STEP 5 FAILED: ALL IDEs were filtered out by installed-app check")
    }

    // MARK: - Test each IDE bundle ID individually

    @Test func cursorBundleIDIsResolvable() {
        let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.todesktop.230313mzl4w4u92")
        #expect(url != nil, "Cursor bundle ID com.todesktop.230313mzl4w4u92 is not resolvable — app not installed or wrong bundle ID")
    }

    @Test func xcodeBundleIDIsResolvable() {
        let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.dt.Xcode")
        // Xcode may or may not be installed, but on a dev machine it should be
        #expect(url != nil, "Xcode bundle ID com.apple.dt.Xcode is not resolvable")
    }

    @Test func vscodeBundleIDIsResolvable() {
        let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.microsoft.VSCode")
        // VS Code may not be installed
        _ = url // Just log, don't fail — this is informational
    }

    // MARK: - Test that BOTH packs fire for code and ranking resolves correctly

    @Test func bothPacksFireForCodeButDevPackWins() async {
        let pipeline = ClassificationPipeline()
        let evaluator = PackEvaluator()
        let fusion = SignalFusion()
        let allPacks = loadRealBuiltInPacks()

        let signal = ContextSignal(
            clipboardUTI: "public.plain-text",
            clipboardSample: ClipboardSamples.swiftCode
        )

        let classification = await pipeline.classify(uti: signal.clipboardUTI, sample: signal.clipboardSample)
        let enriched = fusion.enrich(signal: signal, classification: classification)
        let suggestions = evaluator.evaluate(signal: enriched, packs: allPacks)

        // Development pack fires with code triggers (0.90-0.95 confidence)
        let devSuggestions = suggestions.filter { $0.sourcePackID == "com.iridium.development" }
        #expect(!devSuggestions.isEmpty, "Development pack must fire for code content")

        // Research pack's prose trigger should NOT fire (contentType is code, not prose)
        let proseSuggestions = suggestions.filter {
            $0.sourcePackID == "com.iridium.research" &&
            ["com.apple.iWork.Pages", "com.microsoft.Word", "com.apple.Notes"].contains($0.bundleID)
        }
        #expect(proseSuggestions.isEmpty,
                "Research pack's PROSE trigger should NOT fire for code content")
    }

    // MARK: - Full processSignal simulation without installed-app filter

    @Test func processSignalWithoutInstalledFilterProducesIDEs() async {
        let pipeline = ClassificationPipeline()
        let evaluator = PackEvaluator()
        let ranker = SuggestionRanker()
        let tracker = InteractionTracker()
        let fusion = SignalFusion()
        let allPacks = loadRealBuiltInPacks()

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
        let enriched = fusion.enrich(signal: signal, classification: classification)
        let suggestions = evaluator.evaluate(signal: enriched, packs: allPacks)
        let ranked = ranker.rank(
            suggestions: suggestions,
            signalTimestamp: signal.timestamp,
            interactionTracker: tracker
        )

        // WITHOUT the installed filter, we should see IDE suggestions
        let ideIDs: Set<String> = ["com.todesktop.230313mzl4w4u92", "com.apple.dt.Xcode", "com.microsoft.VSCode"]
        let ides = ranked.filter { ideIDs.contains($0.bundleID) }
        #expect(!ides.isEmpty, "Without installed filter, IDEs must be in ranked results")

        // The top suggestion should be an IDE (dev pack has 0.90-0.95 confidence)
        let proseIDs: Set<String> = ["com.apple.iWork.Pages", "com.microsoft.Word", "com.apple.Notes"]
        let topSuggestion = ranked.first!
        #expect(!proseIDs.contains(topSuggestion.bundleID),
                "Top suggestion for CODE should be an IDE, not \(topSuggestion.bundleID)")
    }

    // MARK: - Test the installed-app filter specifically for IDE bundle IDs

    @Test func atLeastOneIDEBundleIDIsInstalledOnThisMachine() {
        let ideIDs = [
            "com.todesktop.230313mzl4w4u92",  // Cursor
            "com.apple.dt.Xcode",              // Xcode
            "com.microsoft.VSCode",             // VS Code
            "com.jetbrains.pycharm",           // PyCharm
            "com.jetbrains.WebStorm",          // WebStorm
            "com.sublimetext.4",               // Sublime Text
            "dev.zed.Zed",                     // Zed
        ]

        let installedIDEs = ideIDs.filter {
            NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0) != nil
        }

        #expect(!installedIDEs.isEmpty,
                "No IDE bundle IDs resolve on this machine — installed filter removes all code suggestions")
    }
}
