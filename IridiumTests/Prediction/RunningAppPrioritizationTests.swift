//
//  RunningAppPrioritizationTests.swift
//  IridiumTests
//
//  Tests that the SuggestionRanker prioritizes apps that are currently
//  running on the user's system, while still including non-running apps
//  if they are strong matches.
//

import Testing
@testable import Iridium

struct RunningAppPrioritizationTests {

    // MARK: - Running Apps Get Boosted

    @Test func runningAppScoresHigherThanNotRunningApp() {
        let ranker = SuggestionRanker()
        let tracker = InteractionTracker()

        // Two suggestions with identical base confidence
        let suggestions = [
            Suggestion(bundleID: "com.not-running.app", confidence: 0.90, sourcePackID: "test"),
            Suggestion(bundleID: "com.running.app", confidence: 0.90, sourcePackID: "test"),
        ]

        // com.running.app is currently running
        let runningBundleIDs: Set<String> = ["com.running.app"]

        let ranked = ranker.rank(
            suggestions: suggestions,
            signalTimestamp: .now,
            interactionTracker: tracker,
            runningAppBundleIDs: runningBundleIDs
        )

        #expect(ranked.count == 2)
        // Running app should be ranked first due to boost
        #expect(ranked[0].bundleID == "com.running.app")
    }

    @Test func nonRunningAppStillIncludedIfHighConfidence() {
        let ranker = SuggestionRanker()
        let tracker = InteractionTracker()

        let suggestions = [
            Suggestion(bundleID: "com.not-installed.ide", confidence: 0.95, sourcePackID: "test"),
            Suggestion(bundleID: "com.running.editor", confidence: 0.80, sourcePackID: "test"),
        ]

        let runningBundleIDs: Set<String> = ["com.running.editor"]

        let ranked = ranker.rank(
            suggestions: suggestions,
            signalTimestamp: .now,
            interactionTracker: tracker,
            runningAppBundleIDs: runningBundleIDs
        )

        // Both should be included
        #expect(ranked.count == 2)
        // The non-running app has significantly higher confidence (0.95 vs 0.80 + boost)
        // so it may still rank first if the running boost isn't overwhelming
        let bundleIDs = ranked.map(\.bundleID)
        #expect(bundleIDs.contains("com.not-installed.ide"))
        #expect(bundleIDs.contains("com.running.editor"))
    }

    @Test func allRunningAppsGetBoost() {
        let ranker = SuggestionRanker()
        let tracker = InteractionTracker()

        let suggestions = [
            Suggestion(bundleID: "com.app.a", confidence: 0.85, sourcePackID: "test"),
            Suggestion(bundleID: "com.app.b", confidence: 0.85, sourcePackID: "test"),
            Suggestion(bundleID: "com.app.c", confidence: 0.85, sourcePackID: "test"),
        ]

        let runningBundleIDs: Set<String> = ["com.app.a", "com.app.c"]

        let ranked = ranker.rank(
            suggestions: suggestions,
            signalTimestamp: .now,
            interactionTracker: tracker,
            runningAppBundleIDs: runningBundleIDs
        )

        // Non-running app (com.app.b) should be ranked last since a and c are running
        #expect(ranked.last?.bundleID == "com.app.b")
    }

    @Test func emptyRunningAppsDoesNotCrash() {
        let ranker = SuggestionRanker()
        let tracker = InteractionTracker()

        let suggestions = [
            Suggestion(bundleID: "com.app.x", confidence: 0.90, sourcePackID: "test"),
        ]

        let ranked = ranker.rank(
            suggestions: suggestions,
            signalTimestamp: .now,
            interactionTracker: tracker,
            runningAppBundleIDs: []
        )

        #expect(ranked.count == 1)
    }

    @Test func rankWithDefaultRunningAppsParamPreservesBackwardCompat() {
        let ranker = SuggestionRanker()
        let tracker = InteractionTracker()

        let suggestions = [
            Suggestion(bundleID: "com.app.x", confidence: 0.90, sourcePackID: "test"),
        ]

        // Calling without runningAppBundleIDs should still work
        let ranked = ranker.rank(
            suggestions: suggestions,
            signalTimestamp: .now,
            interactionTracker: tracker
        )

        #expect(ranked.count == 1)
    }
}
