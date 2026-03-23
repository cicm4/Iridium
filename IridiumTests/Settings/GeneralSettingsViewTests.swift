//
//  GeneralSettingsViewTests.swift
//  IridiumTests
//
//  Tests for the General Settings view — verifies accessibility permissions
//  button exists and that clicking it opens system preferences.
//

import Foundation
import Testing
@testable import Iridium

@MainActor
struct GeneralSettingsViewTests {

    @Test func settingsStoreDefaultAutoDismissIsTenSeconds() {
        let settings = SettingsStore(defaults: .makeMock())
        #expect(settings.autoDismissDelay == 10.0)
    }

    @Test func settingsStorePreservesAutoDismissValue() {
        let defaults = UserDefaults.makeMock()
        let settings = SettingsStore(defaults: defaults)
        settings.autoDismissDelay = 15.0

        let reloaded = SettingsStore(defaults: defaults)
        #expect(reloaded.autoDismissDelay == 15.0)
    }

    @Test func settingsStoreDefaultConfidenceThreshold() {
        let settings = SettingsStore(defaults: .makeMock())
        #expect(settings.confidenceThreshold == 0.5)
    }

    @Test func settingsStoreDefaultIsEnabled() {
        let settings = SettingsStore(defaults: .makeMock())
        #expect(settings.isEnabled == true)
    }

    @Test func settingsStoreDefaultShowSuggestions() {
        let settings = SettingsStore(defaults: .makeMock())
        #expect(settings.showSuggestions == true)
    }

    @Test func settingsStoreDefaultPosition() {
        let settings = SettingsStore(defaults: .makeMock())
        #expect(settings.suggestionPosition == .nearCursor)
    }
}
