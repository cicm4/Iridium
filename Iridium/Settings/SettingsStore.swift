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
        self.hasCompletedOnboarding = defaults.object(forKey: Keys.hasCompletedOnboarding) as? Bool ?? false

        if let ids = defaults.stringArray(forKey: Keys.enabledPackIDs) {
            self.enabledPackIDs = Set(ids)
        }

        if let data = defaults.data(forKey: Keys.hotkeyBindings),
           let decoded = try? JSONDecoder().decode([HotkeyBinding].self, from: data) {
            self.hotkeyBindings = decoded
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

    var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }

    var enabledPackIDs: Set<String> = [] {
        didSet { defaults.set(Array(enabledPackIDs), forKey: Keys.enabledPackIDs) }
    }

    var hotkeyBindings: [HotkeyBinding] = HotkeyAction.allCases.map(\.defaultBinding) {
        didSet {
            if let data = try? JSONEncoder().encode(hotkeyBindings) {
                defaults.set(data, forKey: Keys.hotkeyBindings)
            }
        }
    }

    func binding(for action: HotkeyAction) -> HotkeyBinding {
        hotkeyBindings.first { $0.action == action } ?? action.defaultBinding
    }

    func updateBinding(for action: HotkeyAction, keyCode: UInt32, modifiers: UInt32) {
        if let index = hotkeyBindings.firstIndex(where: { $0.action == action }) {
            hotkeyBindings[index] = HotkeyBinding(action: action, keyCode: keyCode, modifiers: modifiers)
        }
    }

    func conflictingAction(keyCode: UInt32, modifiers: UInt32, excluding: HotkeyAction) -> HotkeyAction? {
        hotkeyBindings.first { $0.action != excluding && $0.keyCode == keyCode && $0.modifiers == modifiers }?.action
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
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let enabledPackIDs = "enabledPackIDs"
        static let hotkeyBindings = "hotkeyBindings"
    }
}
