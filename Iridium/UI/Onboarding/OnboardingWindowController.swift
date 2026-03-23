//
//  OnboardingWindowController.swift
//  Iridium
//

import AppKit
import SwiftUI

final class OnboardingWindowController {
    private var window: NSWindow?

    func showIfNeeded(coordinator: AppCoordinator, onComplete: @escaping () -> Void) {
        guard !coordinator.settings.hasCompletedOnboarding else {
            onComplete()
            return
        }

        let onboardingView = OnboardingView(onComplete: { [weak self] in
            self?.close()
            onComplete()
        })
        .environment(coordinator)

        let hostingView = NSHostingView(rootView: onboardingView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to Iridium"
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)

        // If the user closes the window via the X button, treat as skip
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            guard let self, self.window != nil else { return }
            coordinator.settings.hasCompletedOnboarding = true
            self.window = nil
            onComplete()
        }

        self.window = window
    }

    private func close() {
        guard let window else { return }
        // Remove the observer before closing to prevent double-firing onComplete
        NotificationCenter.default.removeObserver(self, name: NSWindow.willCloseNotification, object: window)
        window.close()
        self.window = nil
    }
}
