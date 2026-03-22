//
//  DisplaySignalProvider.swift
//  Iridium
//

import AppKit

struct DisplaySignalProvider: Sendable {
    @MainActor
    var displayCount: Int {
        NSScreen.screens.count
    }
}
