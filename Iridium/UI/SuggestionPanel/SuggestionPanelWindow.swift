//
//  SuggestionPanelWindow.swift
//  Iridium
//

import AppKit
import SwiftUI

final class SuggestionPanelWindow: NSPanel {
    /// Called when the user clicks outside the panel or the panel resigns key.
    var onClickOutside: (() -> Void)?

    /// Reference to the view model for forwarding keyboard events.
    /// Must be set before the panel is shown.
    var panelViewModel: SuggestionPanelViewModel?

    /// Reference to the installed app registry for search.
    var installedAppRegistry: InstalledAppRegistry?

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

    /// Intercept key events at the NSPanel level. SwiftUI's .onKeyPress does
    /// not work for .nonActivatingPanel windows because the app is never
    /// activated. We handle arrow keys, Return, Escape, Backspace, and
    /// printable characters (for search) here directly.
    override func keyDown(with event: NSEvent) {
        guard let vm = panelViewModel else {
            super.keyDown(with: event)
            return
        }

        switch event.keyCode {
        case 125: // Down arrow
            vm.moveSelectionDown()
        case 126: // Up arrow
            vm.moveSelectionUp()
        case 36: // Return
            vm.selectCurrent()
        case 53: // Escape
            if vm.isSearching {
                vm.searchQuery = ""
                vm.searchResults = []
            } else {
                vm.dismiss()
            }
        case 51: // Backspace
            vm.backspaceSearch()
            if let registry = installedAppRegistry {
                vm.performSearch(query: vm.searchQuery, using: registry)
            }
        default:
            // Forward printable characters to search
            if let chars = event.characters, !chars.isEmpty,
               chars.unicodeScalars.allSatisfy({ CharacterSet.alphanumerics.union(.whitespaces).contains($0) }) {
                vm.appendToSearch(chars)
                if let registry = installedAppRegistry {
                    vm.performSearch(query: vm.searchQuery, using: registry)
                }
            } else {
                super.keyDown(with: event)
            }
        }
    }
}
