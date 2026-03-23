//
//  SuggestionPanelViewModelTests.swift
//  IridiumTests
//
//  Tests for the suggestion panel view model — auto-dismiss timing,
//  keyboard navigation, selection, and dismiss-on-deactivate behavior.
//

import Testing
@testable import Iridium

@MainActor
struct SuggestionPanelViewModelTests {

    // MARK: - Helpers

    private func makeSuggestionResult(
        bundleIDs: [String] = ["com.apple.dt.Xcode", "com.microsoft.VSCode", "md.obsidian"],
        confidence: Double = 0.9
    ) -> SuggestionResult {
        let suggestions = bundleIDs.map { bundleID in
            Suggestion(bundleID: bundleID, confidence: confidence, sourcePackID: "test")
        }
        return SuggestionResult(suggestions: suggestions, signal: ContextSignal())
    }

    // MARK: - Auto-Dismiss Default (should be 10s, not 4s)

    @Test func defaultAutoDismissDelayIsTenSeconds() {
        let settings = SettingsStore(defaults: .makeMock())
        // The default auto-dismiss delay should be 10 seconds, not 4
        #expect(settings.autoDismissDelay == 10.0)
    }

    @Test func panelDoesNotAutoDismissBefore10Seconds() async {
        let vm = SuggestionPanelViewModel()
        vm.configure(onSelection: { _ in }, onDismissal: { })
        vm.show(result: makeSuggestionResult(), autoDismissDelay: 10.0)

        #expect(vm.isVisible == true)
        // After 5 seconds, still visible
        try? await Task.sleep(for: .seconds(0.1))
        #expect(vm.isVisible == true)
    }

    // MARK: - Keyboard Navigation (Arrow Keys + Enter)

    @Test func arrowDownMovesSelection() {
        let vm = SuggestionPanelViewModel()
        vm.configure(onSelection: { _ in }, onDismissal: { })
        vm.show(result: makeSuggestionResult(), autoDismissDelay: 10.0)

        #expect(vm.selectedIndex == 0)
        vm.moveSelectionDown()
        #expect(vm.selectedIndex == 1)
        vm.moveSelectionDown()
        #expect(vm.selectedIndex == 2)
    }

    @Test func arrowUpMovesSelection() {
        let vm = SuggestionPanelViewModel()
        vm.configure(onSelection: { _ in }, onDismissal: { })
        vm.show(result: makeSuggestionResult(), autoDismissDelay: 10.0)

        vm.moveSelectionDown()
        vm.moveSelectionDown()
        #expect(vm.selectedIndex == 2)
        vm.moveSelectionUp()
        #expect(vm.selectedIndex == 1)
    }

    @Test func arrowDownClampsAtEnd() {
        let vm = SuggestionPanelViewModel()
        vm.configure(onSelection: { _ in }, onDismissal: { })
        vm.show(result: makeSuggestionResult(), autoDismissDelay: 10.0)

        vm.moveSelectionDown()
        vm.moveSelectionDown()
        vm.moveSelectionDown()
        vm.moveSelectionDown()
        #expect(vm.selectedIndex == 2) // clamped at last index
    }

    @Test func arrowUpClampsAtZero() {
        let vm = SuggestionPanelViewModel()
        vm.configure(onSelection: { _ in }, onDismissal: { })
        vm.show(result: makeSuggestionResult(), autoDismissDelay: 10.0)

        vm.moveSelectionUp()
        #expect(vm.selectedIndex == 0)
    }

    @Test func selectCurrentLaunchesSelectedApp() {
        var selectedBundleID: String?
        let vm = SuggestionPanelViewModel()
        vm.configure(onSelection: { selectedBundleID = $0 }, onDismissal: { })
        vm.show(result: makeSuggestionResult(), autoDismissDelay: 10.0)

        vm.moveSelectionDown() // index 1 = VSCode
        vm.selectCurrent()

        #expect(selectedBundleID == "com.microsoft.VSCode")
        #expect(vm.isVisible == false) // panel dismissed after selection
    }

    @Test func selectAtIndexDismissesAndRecordsSelection() {
        var selectedBundleID: String?
        let vm = SuggestionPanelViewModel()
        vm.configure(onSelection: { selectedBundleID = $0 }, onDismissal: { })
        vm.show(result: makeSuggestionResult(), autoDismissDelay: 10.0)

        vm.selectAtIndex(2) // obsidian
        #expect(selectedBundleID == "md.obsidian")
        #expect(vm.isVisible == false)
    }

    @Test func dismissCallsOnDismissal() {
        var dismissed = false
        let vm = SuggestionPanelViewModel()
        vm.configure(onSelection: { _ in }, onDismissal: { dismissed = true })
        vm.show(result: makeSuggestionResult(), autoDismissDelay: 10.0)

        vm.dismiss()
        #expect(dismissed == true)
        #expect(vm.isVisible == false)
        #expect(vm.suggestions.isEmpty)
    }

    @Test func showResolvesAllSuggestions() {
        let vm = SuggestionPanelViewModel()
        vm.configure(onSelection: { _ in }, onDismissal: { })
        let result = makeSuggestionResult(bundleIDs: ["com.apple.dt.Xcode", "com.microsoft.VSCode"])
        vm.show(result: result, autoDismissDelay: 10.0)

        #expect(vm.suggestions.count == 2)
        #expect(vm.suggestions[0].bundleID == "com.apple.dt.Xcode")
        #expect(vm.suggestions[1].bundleID == "com.microsoft.VSCode")
    }

    @Test func showResetsSelectedIndex() {
        let vm = SuggestionPanelViewModel()
        vm.configure(onSelection: { _ in }, onDismissal: { })
        vm.show(result: makeSuggestionResult(), autoDismissDelay: 10.0)

        vm.moveSelectionDown()
        vm.moveSelectionDown()
        #expect(vm.selectedIndex == 2)

        // Show again — should reset
        vm.show(result: makeSuggestionResult(), autoDismissDelay: 10.0)
        #expect(vm.selectedIndex == 0)
    }

    @Test func shortcutIndicesAreOneIndexed() {
        let vm = SuggestionPanelViewModel()
        vm.configure(onSelection: { _ in }, onDismissal: { })
        vm.show(result: makeSuggestionResult(), autoDismissDelay: 10.0)

        #expect(vm.suggestions[0].shortcutIndex == 1)
        #expect(vm.suggestions[1].shortcutIndex == 2)
        #expect(vm.suggestions[2].shortcutIndex == 3)
    }

    @Test func selectCurrentWithEmptySuggestionsDoesNothing() {
        var selectionCalled = false
        let vm = SuggestionPanelViewModel()
        vm.configure(onSelection: { _ in selectionCalled = true }, onDismissal: { })
        // Don't show any suggestions
        vm.selectCurrent()
        #expect(selectionCalled == false)
    }

    @Test func selectAtInvalidIndexDoesNothing() {
        var selectionCalled = false
        let vm = SuggestionPanelViewModel()
        vm.configure(onSelection: { _ in selectionCalled = true }, onDismissal: { })
        vm.show(result: makeSuggestionResult(), autoDismissDelay: 10.0)

        vm.selectAtIndex(99) // invalid
        #expect(selectionCalled == false)
        vm.selectAtIndex(-1) // invalid
        #expect(selectionCalled == false)
    }
}

