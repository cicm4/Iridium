//
//  ToastManager.swift
//  Iridium
//

import AppKit
import Observation
import SwiftUI

struct ToastItem: Identifiable {
    let id = UUID()
    let message: String
    let icon: String
    let duration: TimeInterval

    init(message: String, icon: String, duration: TimeInterval = 2.0) {
        self.message = message
        self.icon = icon
        self.duration = duration
    }
}

@Observable
@MainActor
final class ToastManager {
    static let shared = ToastManager()

    private(set) var currentToast: ToastItem?
    private var dismissTask: Task<Void, Never>?
    private var window: NSPanel?
    private var queue: [ToastItem] = []

    private init() {}

    func show(_ message: String, icon: String = "checkmark.circle.fill") {
        let item = ToastItem(message: message, icon: icon)
        if currentToast != nil {
            queue.append(item)
        } else {
            present(item)
        }
    }

    private func present(_ item: ToastItem) {
        currentToast = item

        if window == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 260, height: 48),
                styleMask: [.nonactivatingPanel, .borderless],
                backing: .buffered,
                defer: true
            )
            panel.level = .floating
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.collectionBehavior = [.canJoinAllSpaces, .transient]
            panel.isMovableByWindowBackground = false
            self.window = panel
        }

        guard let window else { return }

        let toastView = ToastView(item: item)
        let hostingView = NSHostingView(rootView: toastView)
        window.contentView = hostingView

        // Size to fit
        hostingView.layoutSubtreeIfNeeded()
        let fittingSize = hostingView.fittingSize
        window.setContentSize(fittingSize)

        // Position: bottom-center of main screen, above Dock
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - fittingSize.width / 2
            let y = screenFrame.minY + 32
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        // Fade in
        window.alphaValue = 0
        window.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            window.animator().alphaValue = 1.0
        }

        // Schedule auto-dismiss
        dismissTask?.cancel()
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(item.duration))
            guard !Task.isCancelled else { return }
            self.dismiss()
        }
    }

    private func dismiss() {
        guard let window else { return }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            window.animator().alphaValue = 0
        }, completionHandler: {
            window.orderOut(nil)
            self.currentToast = nil

            // Show next queued toast if any
            if !self.queue.isEmpty {
                let next = self.queue.removeFirst()
                self.present(next)
            }
        })
    }
}
