//
//  SuggestionPanelWindow.swift
//  Iridium
//

import AppKit
import SwiftUI

final class SuggestionPanelWindow: NSPanel {
    /// Called when the user clicks outside the panel or the panel resigns key.
    var onClickOutside: (() -> Void)?

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

        // Enable mouse events so clicks on suggestions register
        acceptsMouseMovedEvents = true
        ignoresMouseEvents = false
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// When the panel loses key status (user clicked elsewhere), dismiss it.
    override func resignKey() {
        super.resignKey()
        onClickOutside?()
    }
}
