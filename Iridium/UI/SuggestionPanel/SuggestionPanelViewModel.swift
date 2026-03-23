//
//  SuggestionPanelViewModel.swift
//  Iridium
//

import AppKit
import Observation
import OSLog

@Observable
@MainActor
final class SuggestionPanelViewModel {
    var suggestions: [ResolvedSuggestion] = []
    var selectedIndex: Int = 0
    var isVisible = false

    /// Current search query — when non-empty, panel shows search results instead of suggestions.
    var searchQuery: String = "" {
        didSet {
            selectedIndex = 0
            if isSearching {
                // Cancel auto-dismiss while user is searching
                autoDismissTask?.cancel()
            }
        }
    }

    /// Search results populated by performSearch().
    var searchResults: [ResolvedSuggestion] = []

    /// Whether the panel is in search mode.
    var isSearching: Bool { !searchQuery.isEmpty }

    /// The suggestions currently displayed — either search results or original suggestions.
    var displayedSuggestions: [ResolvedSuggestion] {
        isSearching ? searchResults : suggestions
    }

    private var autoDismissTask: Task<Void, Never>?
    private var onSelection: ((String) -> Void)?
    private var onDismissal: (() -> Void)?
    private var onAutoDismiss: (() -> Void)?

    struct ResolvedSuggestion: Identifiable {
        let id: String
        let bundleID: String
        let name: String
        let icon: NSImage?
        let confidence: Double
        let shortcutIndex: Int
        let contextHint: String?
    }

    func configure(
        onSelection: @escaping (String) -> Void,
        onDismissal: @escaping () -> Void,
        onAutoDismiss: (() -> Void)? = nil
    ) {
        self.onSelection = onSelection
        self.onDismissal = onDismissal
        self.onAutoDismiss = onAutoDismiss
    }

    func show(result: SuggestionResult, autoDismissDelay: TimeInterval) {
        suggestions = result.suggestions.enumerated().map { index, suggestion in
            let info = BundleIDResolver.resolve(bundleID: suggestion.bundleID)
            return ResolvedSuggestion(
                id: suggestion.id,
                bundleID: suggestion.bundleID,
                name: info?.name ?? suggestion.bundleID,
                icon: BundleIDResolver.icon(for: suggestion.bundleID),
                confidence: suggestion.confidence,
                shortcutIndex: index + 1,
                contextHint: suggestion.contextHint
            )
        }
        selectedIndex = 0
        isVisible = true

        scheduleAutoDismiss(delay: autoDismissDelay)
        Logger.ui.debug("Panel shown with \(self.suggestions.count) suggestions")
    }

    /// Explicit dismissal by the user (Escape key, click outside).
    /// This counts toward frequency capping suppression.
    func dismiss() {
        guard isVisible else { return }
        isVisible = false
        suggestions = []
        searchQuery = ""
        searchResults = []
        autoDismissTask?.cancel()
        onDismissal?()
    }

    func selectCurrent() {
        let displayed = displayedSuggestions
        guard !displayed.isEmpty, selectedIndex >= 0, selectedIndex < displayed.count else { return }
        let suggestion = displayed[selectedIndex]
        AppLauncher.launch(bundleID: suggestion.bundleID)
        onSelection?(suggestion.bundleID)
        // Selection dismisses the panel but does NOT count as a dismissal
        isVisible = false
        suggestions = []
        searchQuery = ""
        searchResults = []
        autoDismissTask?.cancel()
    }

    /// Called when the user clicks a specific suggestion row.
    func selectAtIndex(_ index: Int) {
        let displayed = displayedSuggestions
        guard index >= 0, index < displayed.count else { return }
        selectedIndex = index
        selectCurrent()
    }

    func moveSelectionUp() {
        let displayed = displayedSuggestions
        guard !displayed.isEmpty else { return }
        selectedIndex = max(0, selectedIndex - 1)
    }

    func moveSelectionDown() {
        let displayed = displayedSuggestions
        guard !displayed.isEmpty else { return }
        selectedIndex = min(displayed.count - 1, selectedIndex + 1)
    }

    // MARK: - Search

    /// Appends a character to the search query.
    func appendToSearch(_ char: String) {
        searchQuery += char
    }

    /// Removes the last character from the search query.
    func backspaceSearch() {
        guard !searchQuery.isEmpty else { return }
        searchQuery.removeLast()
    }

    /// Searches installed apps by name and populates searchResults.
    func performSearch(query: String, using registry: InstalledAppRegistry) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        let lowered = query.lowercased()
        let matches = registry.apps.values
            .filter { $0.name.lowercased().contains(lowered) }
            .sorted { a, b in
                // Prefix matches first, then alphabetical
                let aPrefix = a.name.lowercased().hasPrefix(lowered)
                let bPrefix = b.name.lowercased().hasPrefix(lowered)
                if aPrefix != bPrefix { return aPrefix }
                return a.name < b.name
            }
            .prefix(10)

        searchResults = matches.enumerated().map { index, app in
            ResolvedSuggestion(
                id: "search:\(app.bundleID)",
                bundleID: app.bundleID,
                name: app.name,
                icon: BundleIDResolver.icon(for: app.bundleID),
                confidence: 0,
                shortcutIndex: index + 1,
                contextHint: nil
            )
        }

        selectedIndex = 0
    }

    private func scheduleAutoDismiss(delay: TimeInterval) {
        autoDismissTask?.cancel()
        autoDismissTask = Task {
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            autoDismiss()
        }
    }

    /// Auto-dismiss: the timer expired without user interaction.
    /// This does NOT count toward frequency capping — the user simply
    /// didn't need the suggestion, which is different from actively dismissing it.
    private func autoDismiss() {
        guard isVisible else { return }
        isVisible = false
        suggestions = []
        autoDismissTask?.cancel()
        onAutoDismiss?()
        Logger.ui.debug("Panel auto-dismissed")
    }
}
