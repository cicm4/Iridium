//
//  CodeDetectionTests.swift
//  IridiumTests
//
//  Tests that the classification pipeline correctly identifies code — even
//  short snippets — and never misclassifies obvious code as prose.
//

import Testing
@testable import Iridium

struct CodeDetectionTests {

    // MARK: - Short code snippets must still be detected as code

    @Test func singleLineSwiftIsCode() async {
        let pipeline = ClassificationPipeline()
        let result = await pipeline.classify(
            uti: "public.plain-text",
            sample: "let x = try await URLSession.shared.data(from: url)"
        )
        #expect(result.contentType == .code)
    }

    @Test func twoLineSwiftFuncIsCode() async {
        let pipeline = ClassificationPipeline()
        let result = await pipeline.classify(
            uti: "public.plain-text",
            sample: """
            func doSomething() {
                print("hello")
            }
            """
        )
        #expect(result.contentType == .code)
    }

    @Test func singleLinePythonIsCode() async {
        let pipeline = ClassificationPipeline()
        let result = await pipeline.classify(
            uti: "public.plain-text",
            sample: "def calculate_total(items): return sum(item.price for item in items)"
        )
        #expect(result.contentType == .code)
    }

    @Test func singleLineJavaScriptIsCode() async {
        let pipeline = ClassificationPipeline()
        let result = await pipeline.classify(
            uti: "public.plain-text",
            sample: "const result = await fetch('/api/data').then(r => r.json());"
        )
        #expect(result.contentType == .code)
    }

    @Test func shortRustIsCode() async {
        let pipeline = ClassificationPipeline()
        let result = await pipeline.classify(
            uti: "public.plain-text",
            sample: "let mut vec: Vec<i32> = Vec::new();"
        )
        #expect(result.contentType == .code)
    }

    @Test func shortGoIsCode() async {
        let pipeline = ClassificationPipeline()
        let result = await pipeline.classify(
            uti: "public.plain-text",
            sample: """
            package main
            func main() { fmt.Println("hello") }
            """
        )
        #expect(result.contentType == .code)
    }

    @Test func variableAssignmentIsCode() async {
        let pipeline = ClassificationPipeline()
        let result = await pipeline.classify(
            uti: "public.plain-text",
            sample: "var result = someFunction(param1: true, param2: 42)"
        )
        #expect(result.contentType == .code)
    }

    @Test func importStatementIsCode() async {
        let pipeline = ClassificationPipeline()
        let result = await pipeline.classify(
            uti: "public.plain-text",
            sample: "import Foundation"
        )
        #expect(result.contentType == .code)
    }

    @Test func codeWithBracesAndSemicolonsIsCode() async {
        let pipeline = ClassificationPipeline()
        let result = await pipeline.classify(
            uti: "public.plain-text",
            sample: "if (x > 0) { return x; } else { return -x; }"
        )
        #expect(result.contentType == .code)
    }

    // MARK: - Generic code indicators (even without language detection)

    @Test func codeWithEqualsAndParensIsCode() async {
        let pipeline = ClassificationPipeline()
        let result = await pipeline.classify(
            uti: "public.plain-text",
            sample: "let result = calculate(a, b) + transform(c);"
        )
        #expect(result.contentType == .code)
    }

    // MARK: - Prose must NOT be classified as code

    @Test func plainEnglishSentenceIsProse() async {
        let pipeline = ClassificationPipeline()
        let result = await pipeline.classify(
            uti: "public.plain-text",
            sample: "The quick brown fox jumps over the lazy dog near the river bank."
        )
        #expect(result.contentType == .prose)
    }

    @Test func paragraphIsProse() async {
        let pipeline = ClassificationPipeline()
        let result = await pipeline.classify(
            uti: "public.plain-text",
            sample: "Today we discussed the quarterly results. Revenue increased by fifteen percent compared to last year. The team is optimistic about next quarter."
        )
        #expect(result.contentType == .prose)
    }

    // MARK: - Code copied from Cursor should trigger dev pack, not research pack

    @Test func codeShouldTriggerDevPackNotResearchPack() async {
        let pipeline = ClassificationPipeline()
        let evaluator = PackEvaluator()
        let fusion = SignalFusion()

        let signal = ContextSignal(
            clipboardUTI: "public.plain-text",
            clipboardSample: ClipboardSamples.swiftCode,
            frontmostAppBundleID: "com.todesktop.230313mzl4w4u92" // Cursor
        )

        let classification = await pipeline.classify(uti: signal.clipboardUTI, sample: signal.clipboardSample)
        let enriched = fusion.enrich(signal: signal, classification: classification)

        #expect(enriched.contentType == .code)

        // Dev pack should fire
        let devPack = PackManifest(
            id: "dev", name: "Dev", version: "1.0.0",
            author: nil, description: nil, minimumIridiumVersion: nil,
            triggers: [
                PackManifest.Trigger(
                    signal: "clipboard.contentType", matches: .exact("code"),
                    conditions: nil, confidence: 0.90,
                    suggest: ["com.todesktop.230313mzl4w4u92", "com.apple.dt.Xcode", "com.microsoft.VSCode"]
                ),
            ]
        )

        // Research pack should NOT fire for code
        let researchPack = PackManifest(
            id: "research", name: "Research", version: "1.0.0",
            author: nil, description: nil, minimumIridiumVersion: nil,
            triggers: [
                PackManifest.Trigger(
                    signal: "clipboard.contentType", matches: .exact("prose"),
                    conditions: nil, confidence: 0.80,
                    suggest: ["com.apple.TextEdit", "com.apple.Notes", "md.obsidian"]
                ),
            ]
        )

        let devSuggestions = evaluator.evaluate(signal: enriched, packs: [devPack])
        let researchSuggestions = evaluator.evaluate(signal: enriched, packs: [researchPack])

        #expect(!devSuggestions.isEmpty, "Dev pack must fire for code")
        #expect(researchSuggestions.isEmpty, "Research pack must NOT fire for code")
    }

    // MARK: - Code-lock and IDE context boost tests

    @Test func tier2CannotOverrideCodeWithProse() async {
        let pipeline = ClassificationPipeline()
        // This text has English-like identifiers but IS code
        let result = await pipeline.classify(
            uti: "public.plain-text",
            sample: "let totalPrice = calculateTotal(items)"
        )
        #expect(result.contentType == .code)
    }

    @Test func copyFromCursorBoostsCodeConfidence() async {
        let pipeline = ClassificationPipeline()
        let result = await pipeline.classify(
            uti: "public.plain-text",
            sample: "let totalPrice = calculateTotal(items)",
            sourceAppBundleID: "com.todesktop.230313mzl4w4u92"
        )
        #expect(result.contentType == .code)
        #expect(result.confidence >= 0.92)
    }

    @Test func copyFromSafariDoesNotBoostProse() async {
        let pipeline = ClassificationPipeline()
        let result = await pipeline.classify(
            uti: "public.plain-text",
            sample: "The meeting is scheduled for tomorrow at three in the afternoon.",
            sourceAppBundleID: "com.apple.Safari"
        )
        #expect(result.contentType == .prose)
    }

    @Test func codeWithEnglishCommentsStaysCode() async {
        let pipeline = ClassificationPipeline()
        let result = await pipeline.classify(
            uti: "public.plain-text",
            sample: """
            // This function calculates the total price
            func calculateTotal(items: [Item]) -> Double {
                return items.reduce(0) { $0 + $1.price }
            }
            """
        )
        #expect(result.contentType == .code)
    }
}
