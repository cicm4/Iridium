//
//  FocusModeProvider.swift
//  Iridium
//

import Foundation

protocol FocusModeProviding: Sendable {
    var isFocusModeActive: Bool { get }
}

struct FocusModeProvider: FocusModeProviding, Sendable {
    /// Checks if Do Not Disturb / Focus Mode is currently active.
    /// Reads from the system notification center DND preferences.
    var isFocusModeActive: Bool {
        // On macOS 12+, Focus Mode state is stored in com.apple.ncprefs
        let dndDefaults = UserDefaults(suiteName: "com.apple.ncprefs")
        // dnd_prefs stores DND configuration; if the key exists and has content, DND is configured
        if let dndPrefs = dndDefaults?.dictionary(forKey: "dnd_prefs"),
           let enabled = dndPrefs["userPref"] as? Int, enabled == 1 {
            return true
        }
        // Fallback: check the control center domain
        let ccDefaults = UserDefaults(suiteName: "com.apple.controlcenter")
        return ccDefaults?.bool(forKey: "NSStatusItem Visible FocusModes") ?? false
    }
}
