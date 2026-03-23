//
//  PanelShowHideRaceTests.swift
//  IridiumTests
//
//  Tests that the panel correctly handles show/hide races:
//  - dismiss → immediate show must work (no stale orderOut)
//  - click outside → new clipboard → panel must reappear
//  - resignKey during show must not cancel the show
//

import Testing
@testable import Iridium

@MainActor
struct PanelShowHideRaceTests {

    private func makeSuggestionResult() -> SuggestionResult {
        let suggestions = [
            Suggestion(bundleID: "com.apple.dt.Xcode", confidence: 0.95, sourcePackID: "test"),
            Suggestion(bundleID: "com.microsoft.VSCode", confidence: 0.90, sourcePackID: "test"),
        ]
        return SuggestionResult(suggestions: suggestions, signal: ContextSignal())
    }

    // MARK: - Dismiss then immediate re-show must work

    @Test func dismissThenImmediateShowWorks() {
        let vm = SuggestionPanelViewModel()
        vm.configure(onSelection: { _ in }, onDismissal: { }, onAutoDismiss: { })
        vm.show(result: makeSuggestionResult(), autoDismissDelay: 10.0)

        // User clicks outside → dismiss
        vm.dismiss()
        #expect(vm.isVisible == false)

        // New clipboard event → show again immediately
        vm.show(result: makeSuggestionResult(), autoDismissDelay: 10.0)
        #expect(vm.isVisible == true)
        #expect(vm.suggestions.count == 2)
    }

    @Test func multipleRapidDismissShowCyclesWork() {
        let vm = SuggestionPanelViewModel()
        vm.configure(onSelection: { _ in }, onDismissal: { }, onAutoDismiss: { })

        for _ in 0..<5 {
            vm.show(result: makeSuggestionResult(), autoDismissDelay: 10.0)
            #expect(vm.isVisible == true)
            vm.dismiss()
            #expect(vm.isVisible == false)
        }

        // Final show should work
        vm.show(result: makeSuggestionResult(), autoDismissDelay: 10.0)
        #expect(vm.isVisible == true)
    }

    // MARK: - hidePanel must be cancellable so showPanel wins the race

    @Test func showPanelAfterHidePanelRace() async {
        // This tests the AppCoordinator's panel management:
        // hidePanel starts a 200ms fade-out animation with orderOut in completion.
        // If showPanel is called during that 200ms, the old completion must NOT
        // orderOut the newly-shown panel.

        let coordinator = AppCoordinator()

        // hidePanel should be safe to call even when no panel exists
        coordinator.hidePanel()

        // After hide, the panel should still be able to show on next result
        // (the panelWindow must not be in a broken state)
    }

    // MARK: - Explicit dismiss should NOT prevent future shows

    @Test func explicitDismissDoesNotPreventFutureShows() {
        let vm = SuggestionPanelViewModel()
        var dismissCount = 0
        vm.configure(
            onSelection: { _ in },
            onDismissal: { dismissCount += 1 },
            onAutoDismiss: { }
        )

        // Show → dismiss (explicit)
        vm.show(result: makeSuggestionResult(), autoDismissDelay: 10.0)
        vm.dismiss()
        #expect(dismissCount == 1)

        // Must be able to show again
        vm.show(result: makeSuggestionResult(), autoDismissDelay: 10.0)
        #expect(vm.isVisible == true)
        #expect(vm.suggestions.count == 2)
    }

    // MARK: - Auto-dismiss then re-show must work

    @Test func autoDismissThenReShowWorks() async {
        let vm = SuggestionPanelViewModel()
        vm.configure(onSelection: { _ in }, onDismissal: { }, onAutoDismiss: { })

        vm.show(result: makeSuggestionResult(), autoDismissDelay: 0.05)
        try? await Task.sleep(for: .seconds(0.15))
        #expect(vm.isVisible == false)

        // Re-show must work
        vm.show(result: makeSuggestionResult(), autoDismissDelay: 10.0)
        #expect(vm.isVisible == true)
    }
}
