//
//  SuggestionRankerTests.swift
//  IridiumTests
//

import Testing
@testable import Iridium

@MainActor
struct SuggestionRankerTests {
    let ranker = SuggestionRanker()

    // MARK: - Ranking Order

    @Test func ranksByConfidenceDescending() {
        let suggestions = [
            Suggestion(bundleID: "com.low", confidence: 0.5, sourcePackID: "p"),
            Suggestion(bundleID: "com.high", confidence: 0.95, sourcePackID: "p"),
            Suggestion(bundleID: "com.mid", confidence: 0.7, sourcePackID: "p"),
        ]
        let tracker = InteractionTracker()
        let ranked = ranker.rank(
            suggestions: suggestions,
            signalTimestamp: .now,
            interactionTracker: tracker
        )
        #expect(ranked[0].bundleID == "com.high")
        #expect(ranked[1].bundleID == "com.mid")
        #expect(ranked[2].bundleID == "com.low")
    }

    // MARK: - Deduplication

    @Test func deduplicatesByBundleID() {
        let suggestions = [
            Suggestion(bundleID: "com.apple.dt.Xcode", confidence: 0.9, sourcePackID: "p1"),
            Suggestion(bundleID: "com.apple.dt.Xcode", confidence: 0.8, sourcePackID: "p2"),
            Suggestion(bundleID: "com.microsoft.VSCode", confidence: 0.7, sourcePackID: "p1"),
        ]
        let tracker = InteractionTracker()
        let ranked = ranker.rank(
            suggestions: suggestions,
            signalTimestamp: .now,
            interactionTracker: tracker
        )
        #expect(ranked.count == 2)
        // Keeps the highest confidence for duplicates
        #expect(ranked[0].bundleID == "com.apple.dt.Xcode")
    }

    // MARK: - Max Suggestions Cap

    @Test func capsAtMaxSuggestions() {
        var suggestions: [Suggestion] = []
        for i in 0..<10 {
            suggestions.append(Suggestion(
                bundleID: "com.app.\(i)",
                confidence: Double(10 - i) / 10.0,
                sourcePackID: "p"
            ))
        }
        let tracker = InteractionTracker()
        let ranked = ranker.rank(
            suggestions: suggestions,
            signalTimestamp: .now,
            interactionTracker: tracker
        )
        #expect(ranked.count == SuggestionResult.maxSuggestions)
    }

    // MARK: - Interaction Boost Affects Ranking

    @Test func interactionBoostMovesAppUp() {
        let suggestions = [
            Suggestion(bundleID: "com.noboost", confidence: 0.85, sourcePackID: "p"),
            Suggestion(bundleID: "com.boosted", confidence: 0.80, sourcePackID: "p"),
        ]
        let tracker = InteractionTracker()
        // Give com.boosted many selections
        for _ in 0..<20 {
            tracker.recordSelection(bundleID: "com.boosted")
        }
        let ranked = ranker.rank(
            suggestions: suggestions,
            signalTimestamp: .now,
            interactionTracker: tracker
        )
        // com.boosted should now rank higher due to boost
        #expect(ranked[0].bundleID == "com.boosted")
    }

    // MARK: - Empty Input

    @Test func emptyInputReturnsEmpty() {
        let tracker = InteractionTracker()
        let ranked = ranker.rank(
            suggestions: [],
            signalTimestamp: .now,
            interactionTracker: tracker
        )
        #expect(ranked.isEmpty)
    }
}
