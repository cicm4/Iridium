//
//  AdaptiveLearningIntegrationTests.swift
//  IridiumTests
//
//  Integration tests verifying adaptive learning affects actual suggestion ranking.
//

import Foundation
import Testing
@testable import Iridium

@Suite("Adaptive Learning Integration")
struct AdaptiveLearningIntegrationTests {

    @Test("Adaptive weight store boosts selected app in ranker")
    func adaptiveBoostInRanker() {
        let store = AdaptiveWeightStore()
        let ranker = SuggestionRanker()
        let tracker = InteractionTracker()

        // Train: heavily prefer Xcode for code (selected 10 times)
        for _ in 0..<10 {
            store.recordSelection(bundleID: "com.apple.dt.Xcode", contentType: .code)
        }
        // VSCode: shown but never selected (only dismissals)
        for _ in 0..<10 {
            store.recordAppearance(bundleID: "com.microsoft.VSCode", contentType: .code)
        }

        let suggestions = [
            Suggestion(bundleID: "com.microsoft.VSCode", confidence: 0.90, sourcePackID: "dev"),
            Suggestion(bundleID: "com.apple.dt.Xcode", confidence: 0.90, sourcePackID: "dev"),
        ]

        let ranked = ranker.rank(
            suggestions: suggestions,
            signalTimestamp: .now,
            interactionTracker: tracker,
            adaptiveWeightStore: store,
            contentType: .code
        )

        #expect(ranked.count == 2)
        // Xcode should rank first due to adaptive boost
        #expect(ranked[0].bundleID == "com.apple.dt.Xcode",
                "Xcode should rank first after being preferred. Got: \(ranked.map(\.bundleID))")
    }

    @Test("Without adaptive store, ranking is unaffected")
    func noStoreNoEffect() {
        let ranker = SuggestionRanker()
        let tracker = InteractionTracker()

        let suggestions = [
            Suggestion(bundleID: "com.app.a", confidence: 0.90, sourcePackID: "test"),
            Suggestion(bundleID: "com.app.b", confidence: 0.85, sourcePackID: "test"),
        ]

        let ranked = ranker.rank(
            suggestions: suggestions,
            signalTimestamp: .now,
            interactionTracker: tracker,
            adaptiveWeightStore: nil,
            contentType: .code
        )

        // Higher confidence should still win without adaptive store
        #expect(ranked[0].bundleID == "com.app.a")
    }

    @Test("InteractionTracker delegates selections to AdaptiveWeightStore")
    func trackerDelegatesToStore() {
        let store = AdaptiveWeightStore()
        let tracker = InteractionTracker()
        tracker.adaptiveWeightStore = store
        tracker.lastContentType = .code

        tracker.recordSelection(bundleID: "com.apple.dt.Xcode")

        // The store should now have data for Xcode
        let known = store.knownBundleIDs(for: .code)
        #expect(known.contains("com.apple.dt.Xcode"),
                "AdaptiveWeightStore should receive selection from InteractionTracker")
    }

    @Test("Persistence round-trip through AdaptiveWeightStore")
    func persistenceRoundTrip() {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("IridiumTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }

        // Create store, add data, save
        let persistence1 = LearningDataPersistence(directory: dir)
        let store1 = AdaptiveWeightStore(persistence: persistence1)

        for _ in 0..<5 {
            store1.recordSelection(bundleID: "com.app.test", contentType: .code)
        }

        // Force immediate write (bypass debounce)
        persistence1.writeImmediately(store1.weights)

        // Create new store, load
        let persistence2 = LearningDataPersistence(directory: dir)
        let store2 = AdaptiveWeightStore(persistence: persistence2)
        store2.load()

        let weight = store2.weight(for: "com.app.test", contentType: .code)
        #expect(weight > 0.0, "Loaded store should have positive weight: \(weight)")
    }

    @Test("Full pipeline: learning improves suggestions over time")
    func fullPipelineLearning() async {
        let store = AdaptiveWeightStore()
        let ranker = SuggestionRanker()
        let tracker = InteractionTracker()
        tracker.adaptiveWeightStore = store
        tracker.lastContentType = .code

        // Both apps start at equal confidence
        let suggestions = [
            Suggestion(bundleID: "com.app.preferred", confidence: 0.85, sourcePackID: "dev"),
            Suggestion(bundleID: "com.app.other", confidence: 0.85, sourcePackID: "dev"),
        ]

        // Before learning: order depends on insertion order (or is arbitrary)
        let beforeRanked = ranker.rank(
            suggestions: suggestions,
            signalTimestamp: .now,
            interactionTracker: tracker,
            adaptiveWeightStore: store,
            contentType: .code
        )
        // Both have same confidence, no learning data
        #expect(beforeRanked.count == 2)

        // Simulate user consistently selecting "preferred" app
        // and dismissing "other" app
        for _ in 0..<8 {
            store.recordSelection(bundleID: "com.app.preferred", contentType: .code)
            store.recordAppearance(bundleID: "com.app.other", contentType: .code)
        }

        // After learning: preferred app should rank first
        let afterRanked = ranker.rank(
            suggestions: suggestions,
            signalTimestamp: .now,
            interactionTracker: tracker,
            adaptiveWeightStore: store,
            contentType: .code
        )

        #expect(afterRanked[0].bundleID == "com.app.preferred",
                "After learning, preferred app should rank first. Got: \(afterRanked.map(\.bundleID))")
        #expect(afterRanked[0].confidence > afterRanked[1].confidence,
                "Preferred should have higher score: \(afterRanked[0].confidence) vs \(afterRanked[1].confidence)")
    }
}
