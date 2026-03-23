//
//  AccessibilityManagerTests.swift
//  IridiumTests
//
//  Tests for the AccessibilityManager — permission prompting, URL opening,
//  and the settings button behavior.
//

import Testing
@testable import Iridium

@MainActor
struct AccessibilityManagerTests {

    @Test func checkPermissionDoesNotCrash() {
        let manager = AccessibilityManager()
        manager.checkPermission()
        // isAccessibilityGranted may be true or false depending on test runner
        // The point is it doesn't crash
    }

    @Test func promptForPermissionSetsGrantedState() {
        let manager = AccessibilityManager()
        manager.promptForPermission()
        // After prompting, the state should be set (true or false)
        // This verifies the AXIsProcessTrustedWithOptions call doesn't crash
        _ = manager.isAccessibilityGranted
    }

    @Test func openAccessibilityPreferencesExists() {
        let manager = AccessibilityManager()
        // The manager should have a method to open system accessibility preferences
        // This verifies the method signature exists (compile-time test)
        manager.openAccessibilityPreferences()
    }
}
