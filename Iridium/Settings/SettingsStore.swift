//
//  SettingsStore.swift
//  Iridium
//

import Foundation
import Observation

enum SuggestionPosition: String, CaseIterable, Identifiable, Codable {
    case nearCursor = "Near Cursor"
    case topRight = "Top Right"
    case bottomRight = "Bottom Right"

    var id: String { rawValue }
}

@Observable
final class SettingsStore {
    let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isEnabled = defaults.object(forKey: Keys.isEnabled) as? Bool ?? true
        self.showSuggestions = defaults.object(forKey: Keys.showSuggestions) as? Bool ?? true
        self.suggestionPosition = SuggestionPosition(rawValue: defaults.string(forKey: Keys.suggestionPosition) ?? "") ?? .nearCursor
        self.autoDismissDelay = defaults.object(forKey: Keys.autoDismissDelay) as? TimeInterval ?? 10.0
        self.confidenceThreshold = defaults.object(forKey: Keys.confidenceThreshold) as? Double ?? 0.5
        self.enableFoundationModels = defaults.object(forKey: Keys.enableFoundationModels) as? Bool ?? false
        self.respectFocusMode = defaults.object(forKey: Keys.respectFocusMode) as? Bool ?? true
        self.enablePersistentLearning = defaults.object(forKey: Keys.enablePersistentLearning) as? Bool ?? false
        self.enableTaskMode = defaults.object(forKey: Keys.enableTaskMode) as? Bool ?? true
        self.enableBrowserTabAnalysis = defaults.object(forKey: Keys.enableBrowserTabAnalysis) as? Bool ?? false
        self.enableCalendarIntegration = defaults.object(forKey: Keys.enableCalendarIntegration) as? Bool ?? false
        self.enableClipboardHistory = defaults.object(forKey: Keys.enableClipboardHistory) as? Bool ?? false
        self.enablePredictiveWorkspace = defaults.object(forKey: Keys.enablePredictiveWorkspace) as? Bool ?? true
        self.enableScreenOCR = defaults.object(forKey: Keys.enableScreenOCR) as? Bool ?? false
        self.hasCompletedWorkspaceMigration = defaults.object(forKey: Keys.hasCompletedWorkspaceMigration) as? Bool ?? false

        if let ids = defaults.stringArray(forKey: Keys.enabledPackIDs) {
            self.enabledPackIDs = Set(ids)
        }
    }

    var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Keys.isEnabled) }
    }

    var showSuggestions: Bool {
        didSet { defaults.set(showSuggestions, forKey: Keys.showSuggestions) }
    }

    var suggestionPosition: SuggestionPosition {
        didSet { defaults.set(suggestionPosition.rawValue, forKey: Keys.suggestionPosition) }
    }

    var autoDismissDelay: TimeInterval {
        didSet { defaults.set(autoDismissDelay, forKey: Keys.autoDismissDelay) }
    }

    var confidenceThreshold: Double {
        didSet { defaults.set(confidenceThreshold, forKey: Keys.confidenceThreshold) }
    }

    var enableFoundationModels: Bool {
        didSet { defaults.set(enableFoundationModels, forKey: Keys.enableFoundationModels) }
    }

    var respectFocusMode: Bool {
        didSet { defaults.set(respectFocusMode, forKey: Keys.respectFocusMode) }
    }

    var enablePersistentLearning: Bool {
        didSet { defaults.set(enablePersistentLearning, forKey: Keys.enablePersistentLearning) }
    }

    var enableTaskMode: Bool {
        didSet { defaults.set(enableTaskMode, forKey: Keys.enableTaskMode) }
    }

    var enableBrowserTabAnalysis: Bool {
        didSet { defaults.set(enableBrowserTabAnalysis, forKey: Keys.enableBrowserTabAnalysis) }
    }

    var enableCalendarIntegration: Bool {
        didSet { defaults.set(enableCalendarIntegration, forKey: Keys.enableCalendarIntegration) }
    }

    var enableClipboardHistory: Bool {
        didSet { defaults.set(enableClipboardHistory, forKey: Keys.enableClipboardHistory) }
    }

    var enablePredictiveWorkspace: Bool {
        didSet { defaults.set(enablePredictiveWorkspace, forKey: Keys.enablePredictiveWorkspace) }
    }

    var enableScreenOCR: Bool {
        didSet { defaults.set(enableScreenOCR, forKey: Keys.enableScreenOCR) }
    }

    var hasCompletedWorkspaceMigration: Bool {
        didSet { defaults.set(hasCompletedWorkspaceMigration, forKey: Keys.hasCompletedWorkspaceMigration) }
    }

    var enabledPackIDs: Set<String> = [] {
        didSet { defaults.set(Array(enabledPackIDs), forKey: Keys.enabledPackIDs) }
    }

    private enum Keys {
        static let isEnabled = "isEnabled"
        static let showSuggestions = "showSuggestions"
        static let suggestionPosition = "suggestionPosition"
        static let autoDismissDelay = "autoDismissDelay"
        static let confidenceThreshold = "confidenceThreshold"
        static let enableFoundationModels = "enableFoundationModels"
        static let respectFocusMode = "respectFocusMode"
        static let enablePersistentLearning = "enablePersistentLearning"
        static let enableTaskMode = "enableTaskMode"
        static let enableBrowserTabAnalysis = "enableBrowserTabAnalysis"
        static let enableCalendarIntegration = "enableCalendarIntegration"
        static let enableClipboardHistory = "enableClipboardHistory"
        static let enablePredictiveWorkspace = "enablePredictiveWorkspace"
        static let enableScreenOCR = "enableScreenOCR"
        static let hasCompletedWorkspaceMigration = "hasCompletedWorkspaceMigration"
        static let enabledPackIDs = "enabledPackIDs"
    }
}
