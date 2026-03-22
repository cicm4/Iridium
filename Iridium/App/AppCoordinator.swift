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

    private var signalCollector: SignalCollector?
    private var signalProcessingTask: Task<Void, Never>?
    private var resultProcessingTask: Task<Void, Never>?
    private var panelWindow: SuggestionPanelWindow?

    private(set) var isRunning = false

    func start() {
        guard !isRunning else { return }
        isRunning = true

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
            }
        )

        // Start signal collection
        let collector = SignalCollector()
        self.signalCollector = collector
        let signalStream = collector.start()

        // Start prediction engine
        let resultStream = predictionEngine.start()

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

        Logger.app.info("Iridium started")
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false

        signalProcessingTask?.cancel()
        resultProcessingTask?.cancel()
        signalCollector?.stop()
        predictionEngine.stop()
        panelViewModel.dismiss()
        hidePanel()

        signalProcessingTask = nil
        resultProcessingTask = nil
        signalCollector = nil

        Logger.app.info("Iridium stopped")
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
            panelWindow = window
        }

        guard let window = panelWindow else { return }

        // Position the panel based on user preference
        positionPanel(window)

        window.alphaValue = 0
        window.orderFrontRegardless()

        // Fade in
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            window.animator().alphaValue = 1.0
        }
    }

    private func hidePanel() {
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

        switch settings.suggestionPosition {
        case .nearCursor:
            let mouseLocation = NSEvent.mouseLocation
            let panelSize = window.frame.size
            let x = min(mouseLocation.x, screenFrame.maxX - panelSize.width)
            let y = max(mouseLocation.y - panelSize.height - 10, screenFrame.minY)
            window.setFrameOrigin(NSPoint(x: x, y: y))

        case .topRight:
            let panelSize = window.frame.size
            let x = screenFrame.maxX - panelSize.width - 16
            let y = screenFrame.maxY - panelSize.height - 16
            window.setFrameOrigin(NSPoint(x: x, y: y))

        case .bottomRight:
            let panelSize = window.frame.size
            let x = screenFrame.maxX - panelSize.width - 16
            let y = screenFrame.minY + 16
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
}
