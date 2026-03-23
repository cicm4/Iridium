//
//  PanelDismissalTests.swift
//  IridiumTests
//
//  Tests for panel dismissal behavior — dismiss on click outside,
//  dismiss on deactivation, and proper cleanup of the panel + bar.
//

import Testing
@testable import Iridium

@MainActor
struct PanelDismissalTests {

    private func makeSuggestionResult() -> SuggestionResult {
        let suggestions = [
            Suggestion(bundleID: "com.apple.dt.Xcode", confidence: 0.9, sourcePackID: "test"),
            Suggestion(bundleID: "com.microsoft.VSCode", confidence: 0.85, sourcePackID: "test"),
        ]
        return SuggestionResult(suggestions: suggestions, signal: ContextSignal())
    }

    // MARK: - Dismiss on click outside

    @Test func dismissClearsVisibilityAndSuggestions() {
        let vm = SuggestionPanelViewModel()
        vm.configure(onSelection: { _ in }, onDismissal: { })
        vm.show(result: makeSuggestionResult(), autoDismissDelay: 10.0)

        #expect(vm.isVisible == true)
        #expect(!vm.suggestions.isEmpty)

        vm.dismiss()

        #expect(vm.isVisible == false)
        #expect(vm.suggestions.isEmpty)
    }

    @Test func dismissCancelsAutoDismissTimer() async {
        var dismissCount = 0
        let vm = SuggestionPanelViewModel()
        vm.configure(onSelection: { _ in }, onDismissal: { dismissCount += 1 })
        vm.show(result: makeSuggestionResult(), autoDismissDelay: 0.2)

        // Dismiss manually before auto-dismiss fires
        vm.dismiss()
        #expect(dismissCount == 1)

        // Wait longer than auto-dismiss would have fired
        try? await Task.sleep(for: .seconds(0.4))

        // Should not have dismissed again
        #expect(dismissCount == 1)
    }

    // MARK: - Panel state after show/dismiss cycles

    @Test func showAfterDismissResetsState() {
        let vm = SuggestionPanelViewModel()
        vm.configure(onSelection: { _ in }, onDismissal: { })
        vm.show(result: makeSuggestionResult(), autoDismissDelay: 10.0)

        vm.moveSelectionDown()
        vm.dismiss()

        // Show again
        vm.show(result: makeSuggestionResult(), autoDismissDelay: 10.0)
        #expect(vm.selectedIndex == 0)
        #expect(vm.isVisible == true)
        #expect(vm.suggestions.count == 2)
    }
}
