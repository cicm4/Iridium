//
//  AutoDismissSuppressionTests.swift
//  IridiumTests
//
//  Tests that auto-dismiss does NOT count as a user dismissal for
//  frequency capping. Only explicit dismissals (Escape, click outside)
//  should suppress future predictions.
//

import Testing
@testable import Iridium

@MainActor
struct AutoDismissSuppressionTests {

    // MARK: - Auto-dismiss must not suppress future predictions

    @Test func autoDismissDoesNotIncrementDismissalCount() async {
        var dismissalCount = 0
        let vm = SuggestionPanelViewModel()
        vm.configure(
            onSelection: { _ in },
            onDismissal: { dismissalCount += 1 }
        )

        let result = makeSuggestionResult()

        // Show and let auto-dismiss fire (very short delay for test)
        vm.show(result: result, autoDismissDelay: 0.05)
        try? await Task.sleep(for: .seconds(0.15))

        // Auto-dismiss should NOT call onDismissal — it should call a
        // separate auto-dismiss path that doesn't count toward suppression
        #expect(dismissalCount == 0)
    }

    @Test func explicitDismissDoesCallOnDismissal() {
        var dismissalCount = 0
        let vm = SuggestionPanelViewModel()
        vm.configure(
            onSelection: { _ in },
            onDismissal: { dismissalCount += 1 }
        )

        vm.show(result: makeSuggestionResult(), autoDismissDelay: 10.0)
        vm.dismiss() // explicit dismiss (Escape / click outside)

        #expect(dismissalCount == 1)
    }

    @Test func threeAutoDismissalsDoNotSuppressPredictions() async {
        let tracker = InteractionTracker()
        let vm = SuggestionPanelViewModel()
        vm.configure(
            onSelection: { _ in },
            onDismissal: { tracker.recordDismissal() }
        )

        // Simulate 3 auto-dismiss cycles
        for _ in 0..<3 {
            vm.show(result: makeSuggestionResult(), autoDismissDelay: 0.05)
            try? await Task.sleep(for: .seconds(0.15))
        }

        // Should NOT be suppressed — auto-dismiss doesn't count
        #expect(!tracker.isSuppressed)
    }

    @Test func threeExplicitDismissalsDoesSuppressPredictions() {
        let tracker = InteractionTracker()
        let vm = SuggestionPanelViewModel()
        vm.configure(
            onSelection: { _ in },
            onDismissal: { tracker.recordDismissal() }
        )

        // Simulate 3 explicit dismiss cycles
        for _ in 0..<3 {
            vm.show(result: makeSuggestionResult(), autoDismissDelay: 10.0)
            vm.dismiss()
        }

        // SHOULD be suppressed — user actively dismissed 3 times
        #expect(tracker.isSuppressed)
    }

    @Test func mixedAutoDismissAndExplicitDoesNotOvercount() async {
        let tracker = InteractionTracker()
        let vm = SuggestionPanelViewModel()
        vm.configure(
            onSelection: { _ in },
            onDismissal: { tracker.recordDismissal() }
        )

        // 2 auto-dismissals (should not count)
        for _ in 0..<2 {
            vm.show(result: makeSuggestionResult(), autoDismissDelay: 0.05)
            try? await Task.sleep(for: .seconds(0.15))
        }

        // 2 explicit dismissals (should count)
        for _ in 0..<2 {
            vm.show(result: makeSuggestionResult(), autoDismissDelay: 10.0)
            vm.dismiss()
        }

        // Only 2 explicit dismissals, threshold is 3, should NOT be suppressed
        #expect(!tracker.isSuppressed)
        #expect(tracker.consecutiveDismissals == 2)
    }

    @Test func subsequentCopiesStillTriggerAfterAutoDismiss() async {
        // Simulates the full flow: copy → prediction → auto-dismiss → copy again → prediction
        let tracker = InteractionTracker()

        // First cycle: auto-dismiss
        let vm = SuggestionPanelViewModel()
        vm.configure(
            onSelection: { _ in },
            onDismissal: { tracker.recordDismissal() }
        )
        vm.show(result: makeSuggestionResult(), autoDismissDelay: 0.05)
        try? await Task.sleep(for: .seconds(0.15))

        // Tracker should NOT be suppressed
        #expect(!tracker.isSuppressed)

        // Second cycle should succeed — signal processing checks isSuppressed
        vm.show(result: makeSuggestionResult(), autoDismissDelay: 10.0)
        #expect(vm.isVisible == true)
        #expect(vm.suggestions.count == 3)
    }

    // MARK: - Helpers

    private func makeSuggestionResult() -> SuggestionResult {
        let suggestions = [
            Suggestion(bundleID: "com.apple.dt.Xcode", confidence: 0.95, sourcePackID: "test"),
            Suggestion(bundleID: "com.microsoft.VSCode", confidence: 0.90, sourcePackID: "test"),
            Suggestion(bundleID: "md.obsidian", confidence: 0.85, sourcePackID: "test"),
        ]
        return SuggestionResult(suggestions: suggestions, signal: ContextSignal())
    }
}
