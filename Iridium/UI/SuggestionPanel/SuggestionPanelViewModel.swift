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

    private var autoDismissTask: Task<Void, Never>?
    private var onSelection: ((String) -> Void)?
    private var onDismissal: (() -> Void)?

    struct ResolvedSuggestion: Identifiable {
        let id: String
        let bundleID: String
        let name: String
        let icon: NSImage?
        let confidence: Double
        let shortcutIndex: Int
    }

    func configure(onSelection: @escaping (String) -> Void, onDismissal: @escaping () -> Void) {
        self.onSelection = onSelection
        self.onDismissal = onDismissal
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
                shortcutIndex: index + 1
            )
        }
        selectedIndex = 0
        isVisible = true

        scheduleAutoDismiss(delay: autoDismissDelay)
        Logger.ui.debug("Panel shown with \(self.suggestions.count) suggestions")
    }

    func dismiss() {
        isVisible = false
        suggestions = []
        autoDismissTask?.cancel()
        onDismissal?()
    }

    func selectCurrent() {
        guard !suggestions.isEmpty, selectedIndex >= 0, selectedIndex < suggestions.count else { return }
        let suggestion = suggestions[selectedIndex]
        AppLauncher.launch(bundleID: suggestion.bundleID)
        onSelection?(suggestion.bundleID)
        dismiss()
    }

    /// Called when the user clicks a specific suggestion row.
    func selectAtIndex(_ index: Int) {
        guard index >= 0, index < suggestions.count else { return }
        selectedIndex = index
        selectCurrent()
    }

    func moveSelectionUp() {
        guard !suggestions.isEmpty else { return }
        selectedIndex = max(0, selectedIndex - 1)
    }

    func moveSelectionDown() {
        guard !suggestions.isEmpty else { return }
        selectedIndex = min(suggestions.count - 1, selectedIndex + 1)
    }

    private func scheduleAutoDismiss(delay: TimeInterval) {
        autoDismissTask?.cancel()
        autoDismissTask = Task {
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            dismiss()
        }
    }
}
