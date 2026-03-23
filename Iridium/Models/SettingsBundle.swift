//
//  SettingsBundle.swift
//  Iridium
//

import Foundation

struct SettingsBundle: Codable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let exportDate: Date

    // General settings
    let isEnabled: Bool
    let showSuggestions: Bool
    let suggestionPosition: String
    let autoDismissDelay: TimeInterval
    let confidenceThreshold: Double
    let enableFoundationModels: Bool
    let respectFocusMode: Bool
    let enablePersistentLearning: Bool
    let enableTaskMode: Bool
    let enableBrowserTabAnalysis: Bool
    let enableCalendarIntegration: Bool
    let enableClipboardHistory: Bool
    let enablePredictiveWorkspace: Bool
    let enableScreenOCR: Bool

    // Pack settings
    let enabledPackIDs: [String]

    // App preferences
    let excludedBundleIDs: [String]
    let pinnedBundleIDs: [String]
    let customMappings: [String: [String]]

    // Hotkey bindings
    let hotkeyBindings: [HotkeyBinding]?

    @MainActor
    static func from(settings: SettingsStore, appPreferences: AppPreferences) -> SettingsBundle {
        SettingsBundle(
            schemaVersion: currentSchemaVersion,
            exportDate: Date(),
            isEnabled: settings.isEnabled,
            showSuggestions: settings.showSuggestions,
            suggestionPosition: settings.suggestionPosition.rawValue,
            autoDismissDelay: settings.autoDismissDelay,
            confidenceThreshold: settings.confidenceThreshold,
            enableFoundationModels: settings.enableFoundationModels,
            respectFocusMode: settings.respectFocusMode,
            enablePersistentLearning: settings.enablePersistentLearning,
            enableTaskMode: settings.enableTaskMode,
            enableBrowserTabAnalysis: settings.enableBrowserTabAnalysis,
            enableCalendarIntegration: settings.enableCalendarIntegration,
            enableClipboardHistory: settings.enableClipboardHistory,
            enablePredictiveWorkspace: settings.enablePredictiveWorkspace,
            enableScreenOCR: settings.enableScreenOCR,
            enabledPackIDs: Array(settings.enabledPackIDs),
            excludedBundleIDs: Array(appPreferences.excludedBundleIDs),
            pinnedBundleIDs: Array(appPreferences.pinnedBundleIDs),
            customMappings: appPreferences.customMappings,
            hotkeyBindings: settings.hotkeyBindings
        )
    }

    @MainActor
    func apply(to settings: SettingsStore, appPreferences: AppPreferences) {
        settings.isEnabled = isEnabled
        settings.showSuggestions = showSuggestions
        settings.suggestionPosition = SuggestionPosition(rawValue: suggestionPosition) ?? .nearCursor
        settings.autoDismissDelay = autoDismissDelay
        settings.confidenceThreshold = confidenceThreshold
        settings.enableFoundationModels = enableFoundationModels
        settings.respectFocusMode = respectFocusMode
        settings.enablePersistentLearning = enablePersistentLearning
        settings.enableTaskMode = enableTaskMode
        settings.enableBrowserTabAnalysis = enableBrowserTabAnalysis
        settings.enableCalendarIntegration = enableCalendarIntegration
        settings.enableClipboardHistory = enableClipboardHistory
        settings.enablePredictiveWorkspace = enablePredictiveWorkspace
        settings.enableScreenOCR = enableScreenOCR
        settings.enabledPackIDs = Set(enabledPackIDs)

        appPreferences.excludedBundleIDs = Set(excludedBundleIDs)
        appPreferences.pinnedBundleIDs = Set(pinnedBundleIDs)
        appPreferences.customMappings = customMappings

        if let bindings = hotkeyBindings {
            settings.hotkeyBindings = bindings
        }
    }
}
