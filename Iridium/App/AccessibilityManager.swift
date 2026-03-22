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
}
