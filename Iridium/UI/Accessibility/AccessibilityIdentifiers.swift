//
//  AccessibilityIdentifiers.swift
//  Iridium
//
//  Centralized accessibility identifiers shared between source and test targets.
//

import Foundation

enum AccessibilityID {
    enum SuggestionPanel {
        static let panel = "suggestionPanel"
        static let header = "suggestionPanel.header"
        static let searchBar = "suggestionPanel.searchBar"
        static let searchHint = "suggestionPanel.searchHint"
        static let noResults = "suggestionPanel.noResults"
        static func row(_ index: Int) -> String { "suggestionPanel.row.\(index)" }
    }

    enum SuggestionRow {
        static let appName = "suggestionRow.appName"
        static let contextHint = "suggestionRow.contextHint"
        static let shortcutBadge = "suggestionRow.shortcutBadge"
        static let returnIcon = "suggestionRow.returnIcon"
    }

    enum ConfidenceBadge {
        static let badge = "confidenceBadge"
    }

    enum MenuBar {
        static let popover = "menuBarPopover"
        static let enableToggle = "menuBar.enableToggle"
        static let statusLabel = "menuBar.statusLabel"
        static let settingsButton = "menuBar.settingsButton"
        static let quitButton = "menuBar.quitButton"
    }

    enum TaskMode {
        static let header = "taskMode.header"
        static let taskInput = "taskMode.taskInput"
        static let startButton = "taskMode.startButton"
        static let stopButton = "taskMode.stopButton"
        static let activeTaskName = "taskMode.activeTaskName"
        static func recentTask(_ index: Int) -> String { "taskMode.recentTask.\(index)" }
    }

    enum Settings {
        static let enableIridiumToggle = "settings.enableIridium"
        static let showSuggestionsToggle = "settings.showSuggestions"
        static let positionPicker = "settings.positionPicker"
        static let confidenceSlider = "settings.confidenceSlider"
        static let foundationModelsToggle = "settings.foundationModels"
        static let persistentLearningToggle = "settings.persistentLearning"
        static let focusModeToggle = "settings.focusMode"
        static let launchAtLoginToggle = "settings.launchAtLogin"
    }

    enum Onboarding {
        static let window = "onboarding.window"
        static let continueButton = "onboarding.continue"
        static let skipButton = "onboarding.skip"
        static let getStartedButton = "onboarding.getStarted"
        static let backButton = "onboarding.back"
        static let accessibilityGrantButton = "onboarding.grantAccessibility"
    }
}
