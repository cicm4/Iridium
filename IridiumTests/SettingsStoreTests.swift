//
//  SettingsStoreTests.swift
//  IridiumTests
//

import Testing
import Foundation
@testable import Iridium

@MainActor
struct SettingsStoreTests {
    private func makeStore() -> SettingsStore {
        let defaults = UserDefaults(suiteName: "test.settings.\(UUID().uuidString)")!
        return SettingsStore(defaults: defaults)
    }

    // MARK: - Defaults

    @Test func defaultsAreCorrect() {
        let store = makeStore()
        #expect(store.isEnabled == true)
        #expect(store.showSuggestions == true)
        #expect(store.suggestionPosition == .nearCursor)
        #expect(store.autoDismissDelay == 4.0)
        #expect(store.confidenceThreshold == 0.5)
        #expect(store.enableFoundationModels == false)
        #expect(store.respectFocusMode == true)
        #expect(store.enablePersistentLearning == false)
        #expect(store.enabledPackIDs.isEmpty)
    }

    // MARK: - Persistence

    @Test func persistsIsEnabled() {
        let suiteName = "test.settings.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let store = SettingsStore(defaults: defaults)
        store.isEnabled = false

        let store2 = SettingsStore(defaults: defaults)
        #expect(store2.isEnabled == false)
    }

    @Test func persistsSuggestionPosition() {
        let suiteName = "test.settings.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let store = SettingsStore(defaults: defaults)
        store.suggestionPosition = .topRight

        let store2 = SettingsStore(defaults: defaults)
        #expect(store2.suggestionPosition == .topRight)
    }

    @Test func persistsEnabledPackIDs() {
        let suiteName = "test.settings.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let store = SettingsStore(defaults: defaults)
        store.enabledPackIDs = ["com.test.pack1", "com.test.pack2"]

        let store2 = SettingsStore(defaults: defaults)
        #expect(store2.enabledPackIDs == ["com.test.pack1", "com.test.pack2"])
    }

    @Test func persistsConfidenceThreshold() {
        let suiteName = "test.settings.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let store = SettingsStore(defaults: defaults)
        store.confidenceThreshold = 0.8

        let store2 = SettingsStore(defaults: defaults)
        #expect(store2.confidenceThreshold == 0.8)
    }

    @Test func persistsAutoDismissDelay() {
        let suiteName = "test.settings.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let store = SettingsStore(defaults: defaults)
        store.autoDismissDelay = 8.0

        let store2 = SettingsStore(defaults: defaults)
        #expect(store2.autoDismissDelay == 8.0)
    }
}
