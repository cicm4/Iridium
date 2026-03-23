//
//  AdaptiveWeightStoreTests.swift
//  IridiumTests
//

import Testing
@testable import Iridium

@Suite("AdaptiveWeightStore")
struct AdaptiveWeightStoreTests {

    @Test("Cold start returns zero weight (no boost)")
    func coldStartReturnsZero() {
        let store = AdaptiveWeightStore()
        let weight = store.weight(for: "com.apple.dt.Xcode", contentType: .code)
        #expect(weight == 0.0, "No data should produce no boost")
    }

    @Test("Repeated selections increase weight")
    func repeatedSelectionsIncreaseWeight() {
        let store = AdaptiveWeightStore()

        // Simulate: user selects Xcode 5 times when shown code suggestions
        for _ in 0..<5 {
            store.recordSelection(bundleID: "com.apple.dt.Xcode", contentType: .code)
        }

        let weight = store.weight(for: "com.apple.dt.Xcode", contentType: .code)
        #expect(weight > 0.0, "Selected app should have positive boost: \(weight)")
        #expect(weight <= AdaptiveWeightStore.maxBoost, "Weight should not exceed max: \(weight)")
    }

    @Test("Never-selected app gets negligible boost after appearances")
    func neverSelectedGetsNegligibleBoost() {
        let store = AdaptiveWeightStore()

        for _ in 0..<10 {
            store.recordAppearance(bundleID: "com.apple.dt.Xcode", contentType: .code)
        }

        let weight = store.weight(for: "com.apple.dt.Xcode", contentType: .code)
        // Never-selected app has low mean → quadratic scaling makes boost negligible
        #expect(weight < 0.02, "Never-selected app should get negligible boost: \(weight)")

        // A selected app should get much more
        let store2 = AdaptiveWeightStore()
        for _ in 0..<10 {
            store2.recordSelection(bundleID: "com.apple.dt.Xcode", contentType: .code)
        }
        let selectedWeight = store2.weight(for: "com.apple.dt.Xcode", contentType: .code)
        #expect(selectedWeight > weight * 5,
                "Selected weight (\(selectedWeight)) should be much higher than ignored (\(weight))")
    }

    @Test("Different content types are independent")
    func contentTypesIndependent() {
        let store = AdaptiveWeightStore()

        // Select Xcode for code (positive selections only)
        for _ in 0..<5 {
            store.recordSelection(bundleID: "com.apple.dt.Xcode", contentType: .code)
        }

        // Xcode should have no weight for prose
        let proseWeight = store.weight(for: "com.apple.dt.Xcode", contentType: .prose)
        #expect(proseWeight == 0.0, "Code selections should not affect prose weight")

        // But should have weight for code
        let codeWeight = store.weight(for: "com.apple.dt.Xcode", contentType: .code)
        #expect(codeWeight > 0.0, "Code selections should produce code weight")
    }

    @Test("Selection produces higher weight than non-selection")
    func selectionBeatsNonSelection() {
        let store = AdaptiveWeightStore()

        // App A: selected 5 times (user picks this one)
        for _ in 0..<5 {
            store.recordSelection(bundleID: "com.app.selected", contentType: .code)
        }

        // App B: shown 5 times but never selected (only appearances = dismissals)
        for _ in 0..<5 {
            store.recordAppearance(bundleID: "com.app.ignored", contentType: .code)
        }

        let selectedWeight = store.weight(for: "com.app.selected", contentType: .code)
        let ignoredWeight = store.weight(for: "com.app.ignored", contentType: .code)

        #expect(selectedWeight > ignoredWeight,
                "Selected app (\(selectedWeight)) should rank higher than ignored (\(ignoredWeight))")
    }

    @Test("Weight is bounded by maxBoost")
    func weightBoundedByMax() {
        let store = AdaptiveWeightStore()

        // Many many selections
        for _ in 0..<100 {
            store.recordSelection(bundleID: "com.app.favorite", contentType: .code)
        }

        let weight = store.weight(for: "com.app.favorite", contentType: .code)
        #expect(weight <= AdaptiveWeightStore.maxBoost,
                "Weight \(weight) exceeds max \(AdaptiveWeightStore.maxBoost)")
    }

    @Test("Reset clears all weights")
    func resetClearsAll() {
        let store = AdaptiveWeightStore()

        for _ in 0..<5 {
            store.recordSelection(bundleID: "com.app.a", contentType: .code)
        }
        #expect(store.weight(for: "com.app.a", contentType: .code) > 0)

        store.reset()
        #expect(store.weight(for: "com.app.a", contentType: .code) == 0.0)
    }

    @Test("knownBundleIDs returns tracked apps")
    func knownBundleIDs() {
        let store = AdaptiveWeightStore()

        store.recordSelection(bundleID: "com.app.a", contentType: .code)
        store.recordSelection(bundleID: "com.app.b", contentType: .code)
        store.recordAppearance(bundleID: "com.app.c", contentType: .prose)

        let codeApps = store.knownBundleIDs(for: .code)
        #expect(codeApps.contains("com.app.a"))
        #expect(codeApps.contains("com.app.b"))
        #expect(!codeApps.contains("com.app.c"), "App C was tracked for prose, not code")
    }
}
