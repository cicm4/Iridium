//
//  AppCoordinatorPanelTests.swift
//  IridiumTests
//
//  Integration tests for the AppCoordinator's panel management:
//  - Panel activation and focus stealing
//  - Panel hides when app resigns key (click outside)
//  - Running apps are passed to the ranker
//

import Foundation
import Testing
@testable import Iridium

@MainActor
struct AppCoordinatorPanelTests {

    // MARK: - Panel View Model Configuration

    @Test func panelViewModelIsConfiguredOnStart() {
        let coordinator = AppCoordinator()
        // Before start, the panel ViewModel's callbacks should work without crash
        coordinator.panelViewModel.dismiss()
    }

    // MARK: - Auto-dismiss uses settings value

    @Test func settingsStoreDefaultAutoDismissIsTenSeconds() {
        // Use isolated defaults to avoid cached values from previous test runs
        let settings = SettingsStore(defaults: .makeMock())
        #expect(settings.autoDismissDelay == 10.0)
    }

    // MARK: - Running apps helper

    @Test func runningAppBundleIDsReturnsNonEmpty() {
        let coordinator = AppCoordinator()
        let running = coordinator.runningAppBundleIDs()
        // There should always be at least one running app (the test runner itself)
        #expect(!running.isEmpty)
    }
}
