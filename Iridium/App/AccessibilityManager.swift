//
//  AccessibilityManager.swift
//  Iridium
//

import AppKit
import Observation

@Observable
final class AccessibilityManager {
    private(set) var isAccessibilityGranted = false

    func checkPermission() {
        isAccessibilityGranted = AXIsProcessTrusted()
    }

    func promptForPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        isAccessibilityGranted = AXIsProcessTrustedWithOptions(options)
    }

    /// Opens System Settings > Privacy & Security > Accessibility directly.
    /// This is the correct way to guide the user to grant accessibility permissions.
    func openAccessibilityPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
