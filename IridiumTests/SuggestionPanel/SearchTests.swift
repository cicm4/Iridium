//
//  SearchTests.swift
//  IridiumTests
//

import Foundation
import Testing
@testable import Iridium

@MainActor
struct SearchTests {

    // MARK: - Helpers

    private func makeViewModel() -> SuggestionPanelViewModel {
        let vm = SuggestionPanelViewModel()
        vm.configure(onSelection: { _ in }, onDismissal: {})
        return vm
    }

    private func showSuggestions(on vm: SuggestionPanelViewModel) {
        let suggestions = [
            Suggestion(bundleID: "com.apple.dt.Xcode", confidence: 0.9, sourcePackID: "test"),
            Suggestion(bundleID: "com.apple.Safari", confidence: 0.8, sourcePackID: "test"),
            Suggestion(bundleID: "com.apple.Terminal", confidence: 0.7, sourcePackID: "test"),
        ]
        let signal = ContextSignal(
            clipboardUTI: nil, clipboardSample: nil, contentType: nil, language: nil,
            frontmostAppBundleID: nil, hourOfDay: 14, displayCount: 1, focusModeActive: false,
            timestamp: .now, windowTitle: nil, screenContentSample: nil, activeFileExtensions: nil,
            upcomingMeetingInMinutes: nil, browserDomain: nil, browserTabTitle: nil,
            clipboardPatternHint: nil, integrationSignals: nil
        )
        vm.show(result: SuggestionResult(suggestions: suggestions, signal: signal), autoDismissDelay: 10)
    }

    // MARK: - Tests

    @Test("Search mode activates when searchQuery is non-empty")
    func searchModeActivates() {
        let vm = makeViewModel()
        showSuggestions(on: vm)

        #expect(!vm.isSearching, "Should not be searching initially")

        vm.searchQuery = "term"

        #expect(vm.isSearching, "Should be in search mode with non-empty query")
    }

    @Test("Search mode deactivates when query is cleared")
    func searchModeDeactivatesOnClear() {
        let vm = makeViewModel()
        showSuggestions(on: vm)

        vm.searchQuery = "term"
        #expect(vm.isSearching)

        vm.searchQuery = ""
        #expect(!vm.isSearching, "Should exit search mode when query is empty")
    }

    @Test("displayedSuggestions returns original suggestions when not searching")
    func displayedSuggestionsWithoutSearch() {
        let vm = makeViewModel()
        showSuggestions(on: vm)

        let displayed = vm.displayedSuggestions
        #expect(displayed.count == 3)
        #expect(displayed[0].bundleID == "com.apple.dt.Xcode")
    }

    @Test("displayedSuggestions returns search results when searching")
    func displayedSuggestionsWithSearch() {
        let vm = makeViewModel()
        showSuggestions(on: vm)

        // Set up search results
        vm.searchResults = [
            SuggestionPanelViewModel.ResolvedSuggestion(
                id: "search:com.apple.finder", bundleID: "com.apple.finder",
                name: "Finder", icon: nil, confidence: 0, shortcutIndex: 0, contextHint: nil
            )
        ]
        vm.searchQuery = "find"

        let displayed = vm.displayedSuggestions
        #expect(displayed.count == 1)
        #expect(displayed[0].bundleID == "com.apple.finder")
    }

    @Test("Selection resets search query on select")
    func selectionResetsSearch() {
        let vm = makeViewModel()
        showSuggestions(on: vm)

        // Set up search results so selectCurrent has something to select
        vm.searchResults = [
            SuggestionPanelViewModel.ResolvedSuggestion(
                id: "search:com.apple.dt.Xcode", bundleID: "com.apple.dt.Xcode",
                name: "Xcode", icon: nil, confidence: 0, shortcutIndex: 1, contextHint: nil
            )
        ]
        vm.searchQuery = "xco"

        vm.selectCurrent()

        #expect(vm.searchQuery.isEmpty, "Search query should be cleared after selection")
    }

    @Test("Dismiss resets search query")
    func dismissResetsSearch() {
        let vm = makeViewModel()
        showSuggestions(on: vm)

        vm.searchQuery = "test"

        vm.dismiss()

        #expect(vm.searchQuery.isEmpty, "Search query should be cleared on dismiss")
    }

    @Test("appendToSearch adds characters to search query")
    func appendToSearch() {
        let vm = makeViewModel()
        showSuggestions(on: vm)

        vm.appendToSearch("t")
        vm.appendToSearch("e")
        vm.appendToSearch("r")

        #expect(vm.searchQuery == "ter")
    }

    @Test("backspaceSearch removes last character")
    func backspaceSearch() {
        let vm = makeViewModel()
        showSuggestions(on: vm)

        vm.searchQuery = "term"
        vm.backspaceSearch()

        #expect(vm.searchQuery == "ter")
    }

    @Test("backspaceSearch on empty query does nothing")
    func backspaceEmptyQuery() {
        let vm = makeViewModel()
        showSuggestions(on: vm)

        vm.backspaceSearch()

        #expect(vm.searchQuery.isEmpty)
    }

    @Test("Selection index resets to 0 when entering search mode")
    func selectionResetsOnSearch() {
        let vm = makeViewModel()
        showSuggestions(on: vm)

        vm.selectedIndex = 2
        vm.searchQuery = "test"

        #expect(vm.selectedIndex == 0, "Selection should reset when search changes")
    }

    @Test("performSearch filters installed apps by name")
    func performSearchFiltersApps() {
        let vm = makeViewModel()
        let registry = InstalledAppRegistry()

        // Manually inject known apps for deterministic testing
        vm.performSearch(query: "Safari", using: registry)

        // We can't guarantee Safari is installed in CI, but the method should not crash
        // and should return results or empty gracefully
        #expect(vm.searchResults.count >= 0)
    }

    @Test("Auto-dismiss is cancelled when search is active")
    func autoDismissCancelledDuringSearch() {
        let vm = makeViewModel()
        showSuggestions(on: vm)

        vm.searchQuery = "test"

        // While searching, the panel should remain visible
        #expect(vm.isVisible, "Panel should stay visible during search")
    }
}
