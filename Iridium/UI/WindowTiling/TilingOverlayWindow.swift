//
//  TilingOverlayWindow.swift
//  Iridium
//

import AppKit
import SwiftUI

final class TilingOverlayWindow: NSPanel {
    var onSelectPreset: ((LayoutPreset) -> Void)?
    var onDismiss: (() -> Void)?

    private let presets: [LayoutPreset]

    init(presets: [LayoutPreset], screenFrame: CGRect) {
        self.presets = presets

        super.init(
            contentRect: screenFrame,
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: true
        )

        level = .floating
        isOpaque = false
        backgroundColor = NSColor.black.withAlphaComponent(0.01)
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .transient]
        isMovableByWindowBackground = false
        ignoresMouseEvents = false
        acceptsMouseMovedEvents = true

        let solver = LayoutSolver()
        let overlayView = TilingOverlayView(
            presets: presets,
            screenFrame: screenFrame,
            solver: solver
        )
        let hostingView = NSHostingView(rootView: overlayView)
        self.contentView = hostingView
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func resignKey() {
        super.resignKey()
        onDismiss?()
    }

    override func keyDown(with event: NSEvent) {
        // Escape dismisses
        if event.keyCode == 53 {
            onDismiss?()
            return
        }

        // Number keys 1-9 select a preset
        if let chars = event.characters, let char = chars.first,
           let digit = char.wholeNumberValue, digit >= 1, digit <= presets.count {
            let preset = presets[digit - 1]
            onSelectPreset?(preset)
            return
        }

        super.keyDown(with: event)
    }
}
