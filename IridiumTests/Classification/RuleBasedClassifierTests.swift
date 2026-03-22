//
//  RuleBasedClassifierTests.swift
//  IridiumTests
//

import Testing
@testable import Iridium

struct RuleBasedClassifierTests {
    let classifier = RuleBasedClassifier()

    // MARK: - UTI-first classification

    @Test func sourceCodeUTIWithSwiftSample() async {
        let result = await classifier.classify(uti: "public.source-code", sample: ClipboardSamples.swiftCode)
        #expect(result.contentType == .code)
        #expect(result.language == .swift)
        #expect(result.confidence >= 0.85)
        #expect(result.tier == .ruleBased)
    }

    @Test func sourceCodeUTIWithoutSample() async {
        let result = await classifier.classify(uti: "public.source-code", sample: nil)
        #expect(result.contentType == .code)
        #expect(result.language == nil || result.language == .unknown)
    }

    @Test func urlUTI() async {
        let result = await classifier.classify(uti: "public.url", sample: nil)
        #expect(result.contentType == .url)
        #expect(result.confidence >= 0.85)
    }

    @Test func imageUTI() async {
        let result = await classifier.classify(uti: "public.image", sample: nil)
        #expect(result.contentType == .image)
    }

    // MARK: - Plain text falls through to pattern matching

    @Test func plainTextWithURL() async {
        let result = await classifier.classify(uti: "public.plain-text", sample: "https://github.com")
        #expect(result.contentType == .url)
    }

    @Test func plainTextWithEmail() async {
        let result = await classifier.classify(uti: "public.plain-text", sample: "user@example.com")
        #expect(result.contentType == .email)
    }

    @Test func plainTextWithCode() async {
        let result = await classifier.classify(uti: "public.plain-text", sample: ClipboardSamples.pythonCode)
        #expect(result.contentType == .code)
        #expect(result.language == .python)
    }

    @Test func plainTextWithProse() async {
        let result = await classifier.classify(uti: "public.plain-text", sample: ClipboardSamples.prose)
        #expect(result.contentType == .prose)
    }

    // MARK: - No information

    @Test func nilUTINilSample() async {
        let result = await classifier.classify(uti: nil, sample: nil)
        #expect(result.contentType == .unknown)
        #expect(result.confidence == 0.0)
    }

    @Test func nilUTIWithCode() async {
        let result = await classifier.classify(uti: nil, sample: ClipboardSamples.swiftCode)
        #expect(result.contentType == .code)
    }

    // MARK: - Performance: Tier 1 should be fast

    @Test func tier1Performance() async {
        let clock = ContinuousClock()
        let start = clock.now
        for _ in 0..<100 {
            _ = await classifier.classify(uti: "public.plain-text", sample: ClipboardSamples.swiftCode)
        }
        let elapsed = clock.now - start
        // 100 classifications should complete in under 1 second (target: <50ms each)
        #expect(elapsed < .seconds(1))
    }
}
