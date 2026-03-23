//
//  AppCoordinator.swift
//  Iridium
//

import AppKit
import Foundation
import Observation
import OSLog
import SwiftUI

@Observable
@MainActor
final class AppCoordinator {
    let settings = SettingsStore()
    let packRegistry = PackRegistry()
    let predictionEngine = PredictionEngine()
    let panelViewModel = SuggestionPanelViewModel()
    let accessibilityManager = AccessibilityManager()
    let windowManager = WindowManager()

    private var signalCollector: SignalCollector?
    private var signalProcessingTask: Task<Void, Never>?
    private var resultProcessingTask: Task<Void, Never>?
    private var panelWindow: SuggestionPanelWindow?

    private(set) var isRunning = false

    func start() {
        guard !isRunning else { return }
        isRunning = true

        // Check accessibility permission for window management
        accessibilityManager.checkPermission()

        // Load packs
        packRegistry.enabledPackIDs = settings.enabledPackIDs
        packRegistry.loadAll()

        // Configure prediction engine
        predictionEngine.configure(packRegistry: packRegistry, settings: settings)

        // Configure panel
        panelViewModel.configure(
            onSelection: { [weak self] bundleID in
                self?.predictionEngine.interactionTracker.recordSelection(bundleID: bundleID)
            },
            onDismissal: { [weak self] in
                self?.predictionEngine.interactionTracker.recordDismissal()
                self?.hidePanel()
            }
        )

        // Start signal collection
        let collector = SignalCollector()
        self.signalCollector = collector
        let signalStream = collector.start()

        // Start prediction engine
        let resultStream = predictionEngine.start()

        // Start window manager (degrades gracefully if no accessibility)
        windowManager.start(accessibilityGranted: accessibilityManager.isAccessibilityGranted)

        // Process signals
        signalProcessingTask = Task {
            for await signal in signalStream {
                await self.predictionEngine.processSignal(signal)
            }
        }

        // Process prediction results → show panel
        resultProcessingTask = Task {
            for await result in resultStream {
                self.panelViewModel.show(
                    result: result,
                    autoDismissDelay: self.settings.autoDismissDelay
                )
                self.showPanel()
            }
        }

        Logger.app.info("Iridium started (accessibility: \(self.accessibilityManager.isAccessibilityGranted))")
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false

        signalProcessingTask?.cancel()
        resultProcessingTask?.cancel()
        signalCollector?.stop()
        predictionEngine.stop()
        windowManager.stop()
        panelViewModel.dismiss()
        hidePanel()

        signalProcessingTask = nil
        resultProcessingTask = nil
        signalCollector = nil

        Logger.app.info("Iridium stopped")
    }

    // MARK: - Running Apps

    /// Returns bundle IDs of all currently running user applications.
    func runningAppBundleIDs() -> Set<String> {
        Set(
            NSWorkspace.shared.runningApplications
                .filter { $0.activationPolicy == .regular }
                .compactMap(\.bundleIdentifier)
        )
    }

    // MARK: - Panel Management

    private func showPanel() {
        if panelWindow == nil {
            let window = SuggestionPanelWindow()
            let hostingView = NSHostingView(
                rootView: SuggestionPanelView()
                    .environment(panelViewModel)
            )
            window.contentView = hostingView

            // Dismiss panel when user clicks outside
            window.onClickOutside = { [weak self] in
                self?.panelViewModel.dismiss()
            }

            panelWindow = window
        }

        guard let window = panelWindow else { return }

        window.alphaValue = 0
        window.orderFrontRegardless()

        // Make the panel key so it receives keyboard events (arrow keys, enter, escape)
        window.makeKey()

        // Layout pass to get correct content size before positioning
        window.layoutIfNeeded()

        // Position the panel based on user preference
        positionPanel(window)

        // Fade in
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            window.animator().alphaValue = 1.0
        }
    }

    func hidePanel() {
        guard let window = panelWindow else { return }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            window.animator().alphaValue = 0
        }, completionHandler: {
            window.orderOut(nil)
        })
    }

    private func positionPanel(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let panelSize = window.frame.size

        let origin: NSPoint
        switch settings.suggestionPosition {
        case .nearCursor:
            let mouseLocation = NSEvent.mouseLocation
            let x = min(mouseLocation.x, screenFrame.maxX - panelSize.width)
            let y = max(mouseLocation.y - panelSize.height - 10, screenFrame.minY)
            origin = NSPoint(x: x, y: y)

        case .topRight:
            let x = screenFrame.maxX - panelSize.width - 16
            let y = screenFrame.maxY - panelSize.height - 16
            origin = NSPoint(x: x, y: y)

        case .bottomRight:
            let x = screenFrame.maxX - panelSize.width - 16
            let y = screenFrame.minY + 16
            origin = NSPoint(x: x, y: y)
        }

        window.setFrameOrigin(origin)
    }
}
