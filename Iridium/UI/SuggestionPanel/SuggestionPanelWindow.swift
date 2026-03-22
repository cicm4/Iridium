//
//  SuggestionPanelWindow.swift
//  Iridium
//

import AppKit
import SwiftUI

final class SuggestionPanelWindow: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 200),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )

        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Don't show in Expose or Mission Control
        collectionBehavior.insert(.stationary)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
