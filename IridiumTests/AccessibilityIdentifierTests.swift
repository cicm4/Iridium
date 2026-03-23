//
//  AccessibilityIdentifierTests.swift
//  IridiumTests
//

import Testing
import AppKit
@testable import Iridium

@MainActor
struct AccessibilityIdentifierTests {
    // MARK: - Suggestion Row Accessibility Label

    @Test func suggestionRowLabelIncludesNameAndConfidence() {
        let suggestion = SuggestionPanelViewModel.ResolvedSuggestion(
            id: "test",
            bundleID: "com.apple.Safari",
            name: "Safari",
            icon: nil,
            confidence: 0.87,
            shortcutIndex: 1,
            contextHint: nil
        )

        let label = accessibilityLabel(for: suggestion)
        #expect(label.contains("Safari"))
        #expect(label.contains("87 percent confidence"))
    }

    @Test func suggestionRowLabelIncludesContextHint() {
        let suggestion = SuggestionPanelViewModel.ResolvedSuggestion(
            id: "test",
            bundleID: "com.apple.Safari",
            name: "Safari",
            icon: nil,
            confidence: 0.75,
            shortcutIndex: 1,
            contextHint: "URL detected"
        )

        let label = accessibilityLabel(for: suggestion)
        #expect(label.contains("Safari"))
        #expect(label.contains("URL detected"))
    }

    @Test func suggestionRowLabelOmitsConfidenceWhenZero() {
        let suggestion = SuggestionPanelViewModel.ResolvedSuggestion(
            id: "search:com.apple.Safari",
            bundleID: "com.apple.Safari",
            name: "Safari",
            icon: nil,
            confidence: 0,
            shortcutIndex: 1,
            contextHint: nil
        )

        let label = accessibilityLabel(for: suggestion)
        #expect(label == "Safari")
        #expect(!label.contains("percent"))
    }

    // MARK: - Identifier Uniqueness

    @Test func panelIdentifiersAreUnique() {
        let ids = [
            AccessibilityID.SuggestionPanel.panel,
            AccessibilityID.SuggestionPanel.header,
            AccessibilityID.SuggestionPanel.searchBar,
            AccessibilityID.SuggestionPanel.searchHint,
            AccessibilityID.SuggestionPanel.noResults,
        ]
        #expect(Set(ids).count == ids.count)
    }

    @Test func settingsIdentifiersAreUnique() {
        let ids = [
            AccessibilityID.Settings.enableIridiumToggle,
            AccessibilityID.Settings.showSuggestionsToggle,
            AccessibilityID.Settings.positionPicker,
            AccessibilityID.Settings.confidenceSlider,
            AccessibilityID.Settings.foundationModelsToggle,
            AccessibilityID.Settings.persistentLearningToggle,
            AccessibilityID.Settings.focusModeToggle,
            AccessibilityID.Settings.launchAtLoginToggle,
        ]
        #expect(Set(ids).count == ids.count)
    }

    @Test func rowIdentifiersAreIndexed() {
        let row0 = AccessibilityID.SuggestionPanel.row(0)
        let row1 = AccessibilityID.SuggestionPanel.row(1)
        #expect(row0 != row1)
        #expect(row0.contains("0"))
        #expect(row1.contains("1"))
    }

    // MARK: - Helper

    /// Mirrors the accessibility label logic from SuggestionRowView.
    private func accessibilityLabel(for suggestion: SuggestionPanelViewModel.ResolvedSuggestion) -> String {
        var parts = [suggestion.name]
        if suggestion.confidence > 0 {
            parts.append("\(Int(suggestion.confidence * 100)) percent confidence")
        }
        if let hint = suggestion.contextHint {
            parts.append(hint)
        }
        return parts.joined(separator: ", ")
    }
}
