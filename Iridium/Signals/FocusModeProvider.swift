//
//  FocusModeProvider.swift
//  Iridium
//

import Foundation

struct FocusModeProvider: Sendable {
    /// Checks if Do Not Disturb / Focus Mode is currently active.
    /// Uses the system defaults domain for DND state.
    var isFocusModeActive: Bool {
        let dndDefaults = UserDefaults(suiteName: "com.apple.controlcenter")
        return dndDefaults?.bool(forKey: "NSStatusItem Visible FocusModes") ?? false
    }
}
