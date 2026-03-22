//
//  ClassificationPipelineTests.swift
//  IridiumTests
//

import Testing
@testable import Iridium

struct ClassificationPipelineTests {
    // MARK: - Tier 1 high confidence bypasses Tier 2

    @Test func highConfidenceURLSkipsTier2() async {
        let pipeline = ClassificationPipeline()
        let result = await pipeline.classify(uti: "public.url", sample: nil)
        #expect(result.contentType == .url)
        #expect(result.confidence >= 0.85)
        // Tier 1 should be sufficient for a clear URL UTI
        #expect(result.tier == .ruleBased)
    }

    // MARK: - Quick classify uses only Tier 1

    @Test func quickClassifyReturnsTier1Only() async {
        let pipeline = ClassificationPipeline()
        let result = await pipeline.quickClassify(uti: "public.plain-text", sample: ClipboardSamples.swiftCode)
        #expect(result.tier == .ruleBased)
    }

    // MARK: - Foundation Models off by default

    @Test func foundationModelsDisabledByDefault() async {
        let pipeline = ClassificationPipeline()
        // Even with low confidence, Tier 3 shouldn't run if disabled
        let result = await pipeline.classify(uti: nil, sample: "ambiguous text content")
        #expect(result.tier != .foundationModel)
    }

    // MARK: - Pipeline never returns nil

    @Test func pipelineAlwaysReturnsResult() async {
        let pipeline = ClassificationPipeline()
        let result = await pipeline.classify(uti: nil, sample: nil)
        // Should return unknown, not crash
        #expect(result.contentType == .unknown)
    }

    // MARK: - Language detection refinement

    @Test func refinesLanguageForCodeUTI() async {
        let pipeline = ClassificationPipeline()
        let result = await pipeline.classify(uti: "public.source-code", sample: ClipboardSamples.pythonCode)
        #expect(result.contentType == .code)
        // Should detect Python even though UTI is generic source-code
        #expect(result.language == .python)
    }
}
