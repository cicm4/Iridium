//
//  SettingsExportImportTests.swift
//  IridiumTests
//

import Testing
import Foundation
@testable import Iridium

@MainActor
struct SettingsExportImportTests {
    private func makeStore() -> SettingsStore {
        let defaults = UserDefaults(suiteName: "test.export.\(UUID().uuidString)")!
        return SettingsStore(defaults: defaults)
    }

    private func makePrefs() -> AppPreferences {
        let defaults = UserDefaults(suiteName: "test.export.prefs.\(UUID().uuidString)")!
        return AppPreferences(defaults: defaults)
    }

    // MARK: - Round-Trip

    @Test func roundTripProducesIdenticalSettings() throws {
        let store = makeStore()
        let prefs = makePrefs()

        // Customize settings
        store.isEnabled = false
        store.confidenceThreshold = 0.8
        store.autoDismissDelay = 5.0
        store.enableFoundationModels = true
        store.enabledPackIDs = ["pack1", "pack2"]
        prefs.pinnedBundleIDs = ["com.app.one"]
        prefs.excludedBundleIDs = ["com.app.two"]
        prefs.customMappings = ["code": ["com.app.editor"]]

        // Export
        let bundle = SettingsBundle.from(settings: store, appPreferences: prefs)

        // Encode/decode (simulates file write/read)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(bundle)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let restored = try decoder.decode(SettingsBundle.self, from: data)

        // Import into fresh store
        let store2 = makeStore()
        let prefs2 = makePrefs()
        restored.apply(to: store2, appPreferences: prefs2)

        // Verify
        #expect(store2.isEnabled == false)
        #expect(store2.confidenceThreshold == 0.8)
        #expect(store2.autoDismissDelay == 5.0)
        #expect(store2.enableFoundationModels == true)
        #expect(store2.enabledPackIDs == ["pack1", "pack2"])
        #expect(prefs2.pinnedBundleIDs == ["com.app.one"])
        #expect(prefs2.excludedBundleIDs == ["com.app.two"])
        #expect(prefs2.customMappings == ["code": ["com.app.editor"]])
    }

    // MARK: - Schema Version

    @Test func currentSchemaVersionIsValid() {
        #expect(SettingsBundle.currentSchemaVersion >= 1)
    }

    @Test func validateRejectsFutureVersion() throws {
        let bundle = SettingsBundle(
            schemaVersion: 999,
            exportDate: Date(),
            isEnabled: true,
            showSuggestions: true,
            suggestionPosition: "Near Cursor",
            autoDismissDelay: 10,
            confidenceThreshold: 0.5,
            enableFoundationModels: false,
            respectFocusMode: true,
            enablePersistentLearning: false,
            enableTaskMode: true,
            enableBrowserTabAnalysis: false,
            enableCalendarIntegration: false,
            enableClipboardHistory: false,
            enablePredictiveWorkspace: true,
            enableScreenOCR: false,
            enabledPackIDs: [],
            excludedBundleIDs: [],
            pinnedBundleIDs: [],
            customMappings: [:],
            hotkeyBindings: nil
        )

        #expect(throws: SettingsImporter.ImportError.self) {
            try SettingsImporter.validate(bundle)
        }
    }

    @Test func validateAcceptsCurrentVersion() throws {
        let bundle = SettingsBundle(
            schemaVersion: SettingsBundle.currentSchemaVersion,
            exportDate: Date(),
            isEnabled: true,
            showSuggestions: true,
            suggestionPosition: "Near Cursor",
            autoDismissDelay: 10,
            confidenceThreshold: 0.5,
            enableFoundationModels: false,
            respectFocusMode: true,
            enablePersistentLearning: false,
            enableTaskMode: true,
            enableBrowserTabAnalysis: false,
            enableCalendarIntegration: false,
            enableClipboardHistory: false,
            enablePredictiveWorkspace: true,
            enableScreenOCR: false,
            enabledPackIDs: [],
            excludedBundleIDs: [],
            pinnedBundleIDs: [],
            customMappings: [:],
            hotkeyBindings: nil
        )

        // Should not throw
        try SettingsImporter.validate(bundle)
    }

    // MARK: - Hotkey Bindings Optional

    @Test func importWithoutHotkeyBindingsDoesNotOverwrite() throws {
        let store = makeStore()
        let prefs = makePrefs()
        let originalBindings = store.hotkeyBindings

        let bundle = SettingsBundle(
            schemaVersion: 1,
            exportDate: Date(),
            isEnabled: true,
            showSuggestions: true,
            suggestionPosition: "Near Cursor",
            autoDismissDelay: 10,
            confidenceThreshold: 0.5,
            enableFoundationModels: false,
            respectFocusMode: true,
            enablePersistentLearning: false,
            enableTaskMode: true,
            enableBrowserTabAnalysis: false,
            enableCalendarIntegration: false,
            enableClipboardHistory: false,
            enablePredictiveWorkspace: true,
            enableScreenOCR: false,
            enabledPackIDs: [],
            excludedBundleIDs: [],
            pinnedBundleIDs: [],
            customMappings: [:],
            hotkeyBindings: nil
        )

        bundle.apply(to: store, appPreferences: prefs)
        #expect(store.hotkeyBindings == originalBindings)
    }

    // MARK: - Export Date

    @Test func exportBundleContainsValidDate() {
        let store = makeStore()
        let prefs = makePrefs()
        let bundle = SettingsBundle.from(settings: store, appPreferences: prefs)
        #expect(bundle.exportDate.timeIntervalSinceNow < 1.0)
        #expect(bundle.exportDate.timeIntervalSinceNow > -1.0)
    }
}
