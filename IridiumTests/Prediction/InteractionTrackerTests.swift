//
//  InteractionTrackerTests.swift
//  IridiumTests
//

import Testing
@testable import Iridium

@MainActor
struct InteractionTrackerTests {
    // MARK: - Selection Tracking

    @Test func recordsSelection() {
        let tracker = InteractionTracker()
        tracker.recordSelection(bundleID: "com.apple.dt.Xcode")
        #expect(tracker.selectionCounts["com.apple.dt.Xcode"] == 1)
    }

    @Test func incrementsSelectionCount() {
        let tracker = InteractionTracker()
        tracker.recordSelection(bundleID: "com.apple.dt.Xcode")
        tracker.recordSelection(bundleID: "com.apple.dt.Xcode")
        tracker.recordSelection(bundleID: "com.apple.dt.Xcode")
        #expect(tracker.selectionCounts["com.apple.dt.Xcode"] == 3)
    }

    @Test func tracksMultipleBundleIDs() {
        let tracker = InteractionTracker()
        tracker.recordSelection(bundleID: "com.apple.dt.Xcode")
        tracker.recordSelection(bundleID: "com.microsoft.VSCode")
        #expect(tracker.selectionCounts.count == 2)
    }

    // MARK: - Dismissal Tracking

    @Test func recordsDismissal() {
        let tracker = InteractionTracker()
        tracker.recordDismissal()
        #expect(tracker.consecutiveDismissals == 1)
    }

    @Test func selectionResetsDismissalCount() {
        let tracker = InteractionTracker()
        tracker.recordDismissal()
        tracker.recordDismissal()
        tracker.recordSelection(bundleID: "com.test")
        #expect(tracker.consecutiveDismissals == 0)
    }

    // MARK: - Frequency Capping (Suppression)

    @Test func notSuppressedInitially() {
        let tracker = InteractionTracker()
        #expect(!tracker.isSuppressed)
    }

    @Test func suppressedAfterThreeDismissals() {
        let tracker = InteractionTracker()
        tracker.recordDismissal()
        tracker.recordDismissal()
        #expect(!tracker.isSuppressed)
        tracker.recordDismissal()
        #expect(tracker.isSuppressed)
    }

    @Test func selectionUnsuppresses() {
        let tracker = InteractionTracker()
        tracker.recordDismissal()
        tracker.recordDismissal()
        tracker.recordDismissal()
        #expect(tracker.isSuppressed)
        tracker.recordSelection(bundleID: "com.test")
        #expect(!tracker.isSuppressed)
    }

    // MARK: - Confidence Boost

    @Test func noBoostForUnknownApp() {
        let tracker = InteractionTracker()
        #expect(tracker.boostForBundleID("com.unknown") == 0.0)
    }

    @Test func boostIncreasesWithSelections() {
        let tracker = InteractionTracker()
        tracker.recordSelection(bundleID: "com.test")
        let boost1 = tracker.boostForBundleID("com.test")
        tracker.recordSelection(bundleID: "com.test")
        let boost2 = tracker.boostForBundleID("com.test")
        #expect(boost2 > boost1)
        #expect(boost1 > 0)
    }

    @Test func boostCapsAtMaximum() {
        let tracker = InteractionTracker()
        for _ in 0..<100 {
            tracker.recordSelection(bundleID: "com.test")
        }
        let boost = tracker.boostForBundleID("com.test")
        #expect(boost <= 0.15)
    }

    // MARK: - Reset

    @Test func resetClearsEverything() {
        let tracker = InteractionTracker()
        tracker.recordSelection(bundleID: "com.test")
        tracker.recordDismissal()
        tracker.recordDismissal()
        tracker.recordDismissal()
        tracker.reset()
        #expect(tracker.selectionCounts.isEmpty)
        #expect(tracker.consecutiveDismissals == 0)
        #expect(!tracker.isSuppressed)
    }
}
