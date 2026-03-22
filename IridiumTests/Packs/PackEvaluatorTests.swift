//
//  PackEvaluatorTests.swift
//  IridiumTests
//

import Testing
@testable import Iridium

struct PackEvaluatorTests {
    let evaluator = PackEvaluator()

    private func makePack(
        id: String = "com.test",
        triggers: [PackManifest.Trigger]
    ) -> PackManifest {
        PackManifest(
            id: id, name: "Test", version: "1.0.0",
            author: nil, description: nil, minimumIridiumVersion: nil,
            triggers: triggers
        )
    }

    // MARK: - Basic Evaluation

    @Test func matchingTriggerProducesSuggestions() {
        let pack = makePack(triggers: [
            PackManifest.Trigger(
                signal: "clipboard.contentType", matches: .exact("code"),
                conditions: nil, confidence: 0.9,
                suggest: ["com.apple.dt.Xcode", "com.microsoft.VSCode"]
            )
        ])

        let signal = ContextSignal(contentType: .code)
        let results = evaluator.evaluate(signal: signal, packs: [pack])

        #expect(results.count == 2)
        #expect(results[0].bundleID == "com.apple.dt.Xcode")
        #expect(results[1].bundleID == "com.microsoft.VSCode")
        #expect(results[0].confidence == 0.9)
    }

    @Test func nonMatchingTriggerProducesNothing() {
        let pack = makePack(triggers: [
            PackManifest.Trigger(
                signal: "clipboard.contentType", matches: .exact("url"),
                conditions: nil, confidence: 0.9,
                suggest: ["com.apple.Safari"]
            )
        ])

        let signal = ContextSignal(contentType: .code)
        let results = evaluator.evaluate(signal: signal, packs: [pack])

        #expect(results.isEmpty)
    }

    // MARK: - Multiple Packs

    @Test func multiplePacksProduceCombinedResults() {
        let pack1 = makePack(id: "com.test.1", triggers: [
            PackManifest.Trigger(
                signal: "clipboard.contentType", matches: .exact("code"),
                conditions: nil, confidence: 0.9,
                suggest: ["com.apple.dt.Xcode"]
            )
        ])
        let pack2 = makePack(id: "com.test.2", triggers: [
            PackManifest.Trigger(
                signal: "clipboard.contentType", matches: .exact("code"),
                conditions: nil, confidence: 0.8,
                suggest: ["com.microsoft.VSCode"]
            )
        ])

        let signal = ContextSignal(contentType: .code)
        let results = evaluator.evaluate(signal: signal, packs: [pack1, pack2])

        #expect(results.count == 2)
        let bundleIDs = Set(results.map(\.bundleID))
        #expect(bundleIDs.contains("com.apple.dt.Xcode"))
        #expect(bundleIDs.contains("com.microsoft.VSCode"))
    }

    // MARK: - Empty Packs

    @Test func emptyPacksProducesNothing() {
        let signal = ContextSignal(contentType: .code)
        let results = evaluator.evaluate(signal: signal, packs: [])
        #expect(results.isEmpty)
    }

    // MARK: - Source Pack ID Tracking

    @Test func suggestionTracksSourcePack() {
        let pack = makePack(id: "com.iridium.dev", triggers: [
            PackManifest.Trigger(
                signal: "clipboard.contentType", matches: .exact("code"),
                conditions: nil, confidence: 0.9,
                suggest: ["com.apple.dt.Xcode"]
            )
        ])

        let signal = ContextSignal(contentType: .code)
        let results = evaluator.evaluate(signal: signal, packs: [pack])

        #expect(results[0].sourcePackID == "com.iridium.dev")
    }
}
