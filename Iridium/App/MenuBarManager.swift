//
//  MenuBarManager.swift
//  Iridium
//

import AppKit
import SwiftUI

@MainActor
final class MenuBarManager {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private let coordinator: AppCoordinator

    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }

    func setup() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "sparkle", accessibilityDescription: "Iridium")
            button.action = #selector(togglePopover)
            button.target = self
        }

        self.statusItem = statusItem

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarPopoverView()
                .environment(coordinator)
        )
        self.popover = popover
    }

    @objc private func togglePopover() {
        guard let popover, let button = statusItem?.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
