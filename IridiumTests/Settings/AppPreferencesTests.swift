//
//  AppPreferencesTests.swift
//  IridiumTests
//

import Foundation
import Testing
@testable import Iridium

@MainActor
struct AppPreferencesTests {
    @Test func excludedBundleIDsPersist() {
        let defaults = UserDefaults.makeMock()
        let prefs = AppPreferences(defaults: defaults)
        prefs.excludedBundleIDs = ["com.apple.TextEdit", "com.apple.Notes"]

        let reloaded = AppPreferences(defaults: defaults)
        #expect(reloaded.excludedBundleIDs.contains("com.apple.TextEdit"))
        #expect(reloaded.excludedBundleIDs.contains("com.apple.Notes"))
    }

    @Test func pinnedBundleIDsPersist() {
        let defaults = UserDefaults.makeMock()
        let prefs = AppPreferences(defaults: defaults)
        prefs.pinnedBundleIDs = ["com.todesktop.230313mzl4w4u92"]

        let reloaded = AppPreferences(defaults: defaults)
        #expect(reloaded.pinnedBundleIDs.contains("com.todesktop.230313mzl4w4u92"))
    }

    @Test func customMappingsPersist() {
        let defaults = UserDefaults.makeMock()
        let prefs = AppPreferences(defaults: defaults)
        prefs.customMappings = ["code": ["com.todesktop.230313mzl4w4u92", "com.apple.dt.Xcode"]]

        let reloaded = AppPreferences(defaults: defaults)
        #expect(reloaded.customMappings["code"]?.count == 2)
        #expect(reloaded.customMappings["code"]?.contains("com.todesktop.230313mzl4w4u92") == true)
    }

    @Test func excludedAppsRemovedFromRankerResults() {
        let ranker = SuggestionRanker()
        let tracker = InteractionTracker()
        let suggestions = [
            Suggestion(bundleID: "com.apple.dt.Xcode", confidence: 0.95, sourcePackID: "test"),
            Suggestion(bundleID: "com.apple.TextEdit", confidence: 0.90, sourcePackID: "test"),
            Suggestion(bundleID: "com.microsoft.VSCode", confidence: 0.85, sourcePackID: "test"),
        ]

        let ranked = ranker.rank(
            suggestions: suggestions,
            signalTimestamp: .now,
            interactionTracker: tracker,
            excludedBundleIDs: ["com.apple.TextEdit"]
        )

        let bundleIDs = ranked.map(\.bundleID)
        #expect(!bundleIDs.contains("com.apple.TextEdit"))
        #expect(bundleIDs.contains("com.apple.dt.Xcode"))
        #expect(bundleIDs.contains("com.microsoft.VSCode"))
    }

    @Test func pinnedAppsRankFirst() {
        let ranker = SuggestionRanker()
        let tracker = InteractionTracker()
        let suggestions = [
            Suggestion(bundleID: "com.apple.dt.Xcode", confidence: 0.95, sourcePackID: "test"),
            Suggestion(bundleID: "com.microsoft.VSCode", confidence: 0.80, sourcePackID: "test"),
        ]

        let ranked = ranker.rank(
            suggestions: suggestions,
            signalTimestamp: .now,
            interactionTracker: tracker,
            pinnedBundleIDs: ["com.microsoft.VSCode"]
        )

        // VSCode should be first despite lower base confidence, due to +0.25 pin boost
        #expect(ranked[0].bundleID == "com.microsoft.VSCode")
    }
}
