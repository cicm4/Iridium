//
//  AppCoordinator.swift
//  Iridium
//

import AppKit
import Carbon
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
    let appPreferences = AppPreferences()
    let installedAppRegistry = InstalledAppRegistry()
    let adaptiveWeightStore: AdaptiveWeightStore
    let taskStore = TaskStore()
    let workspaceStore = WorkspaceStore()
    let workspaceLearner = WorkspaceLearner()
    let integrationRegistry = IntegrationRegistry()
    private(set) var workspaceHotkeyHandler: WorkspaceHotkeyHandler?

    nonisolated init() {
        let persistence = LearningDataPersistence()
        self.adaptiveWeightStore = AdaptiveWeightStore(persistence: persistence)
    }

    private var signalCollector: SignalCollector?
    private var signalProcessingTask: Task<Void, Never>?
    private var resultProcessingTask: Task<Void, Never>?
    private var panelWindow: SuggestionPanelWindow?
    /// Incremented each time showPanel/hidePanel is called.
    /// hidePanel's completion handler checks this to avoid stale orderOut.
    private var panelShowHideGeneration: Int = 0

    private(set) var isRunning = false

    func start() {
        guard !isRunning else { return }
        isRunning = true

        // Check accessibility permission for window management
        accessibilityManager.checkPermission()

        // Load packs
        packRegistry.loadAll()

        // On first launch, enabledPackIDs is empty — auto-enable all built-in packs
        if settings.enabledPackIDs.isEmpty && !packRegistry.packs.isEmpty {
            let builtInIDs = Set(packRegistry.packs.map(\.id))
            settings.enabledPackIDs = builtInIDs
            Logger.app.info("First launch: auto-enabled \(builtInIDs.count) built-in packs")
        }
        packRegistry.enabledPackIDs = settings.enabledPackIDs

        // Load adaptive weights if persistent learning is enabled
        if settings.enablePersistentLearning {
            adaptiveWeightStore.load()
        }

        // Scan installed apps in the background
        Task.detached { [installedAppRegistry] in
            installedAppRegistry.scan()
        }
        installedAppRegistry.startObservingLaunches()

        // Configure prediction engine
        predictionEngine.configure(packRegistry: packRegistry, settings: settings)
        predictionEngine.appPreferences = appPreferences
        predictionEngine.adaptiveWeightStore = settings.enablePersistentLearning ? adaptiveWeightStore : nil
        predictionEngine.installedAppRegistry = installedAppRegistry

        // Wire adaptive learning into interaction tracker
        predictionEngine.interactionTracker.adaptiveWeightStore = settings.enablePersistentLearning ? adaptiveWeightStore : nil

        // Load task store and wire into prediction engine
        if settings.enableTaskMode {
            taskStore.load()
            predictionEngine.taskStore = taskStore
        }

        // Load workspaces (for migration)
        workspaceStore.load()

        // Migrate old preset workspaces to learned data (one-time)
        if !settings.hasCompletedWorkspaceMigration && !workspaceStore.workspaces.isEmpty {
            let migrator = WorkspaceMigrator()
            migrator.migrate(from: workspaceStore.workspaces, into: workspaceLearner)
            settings.hasCompletedWorkspaceMigration = true
            Logger.app.info("Migrated \(self.workspaceStore.workspaces.count) preset workspaces to learned data")
        }

        // Set up predictive window manager
        if settings.enablePredictiveWorkspace {
            setupPredictiveWorkspace()
        }

        // Register and start integrations
        integrationRegistry.register(TodoistIntegration())
        integrationRegistry.register(ObsidianIntegration())
        integrationRegistry.register(NotionIntegration())
        if let enabledIDs = settings.defaults.stringArray(forKey: "enabledIntegrationIDs") {
            integrationRegistry.enabledIDs = Set(enabledIDs)
        }
        Task {
            await integrationRegistry.startAll()
        }

        // Configure panel
        panelViewModel.configure(
            onSelection: { [weak self] bundleID in
                guard let self else { return }
                self.predictionEngine.interactionTracker.recordSelection(bundleID: bundleID)

                // If workspace prediction is active, also arrange the window
                if let handler = self.workspaceHotkeyHandler, handler.isActive {
                    Task {
                        await handler.handleSelection(bundleID: bundleID)
                    }
                }

                self.hidePanel()
            },
            onDismissal: { [weak self] in
                // Explicit dismissal (Escape, click outside) counts toward suppression
                self?.predictionEngine.interactionTracker.recordDismissal()
                self?.workspaceHotkeyHandler?.handleDismissal()
                self?.hidePanel()
            },
            onAutoDismiss: { [weak self] in
                // Auto-dismiss does NOT count toward suppression —
                // the user simply didn't need the suggestion
                self?.workspaceHotkeyHandler?.handleDismissal()
                self?.hidePanel()
            }
        )

        // Start signal collection with enhanced providers
        let collector = SignalCollector()
        collector.configureEnhancedProviders(
            enableBrowserTabAnalysis: settings.enableBrowserTabAnalysis,
            enableCalendarIntegration: settings.enableCalendarIntegration,
            enableClipboardHistory: settings.enableClipboardHistory
        )
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
        installedAppRegistry.stopObservingLaunches()
        Task { await integrationRegistry.stopAll() }

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

            // Wire up the view model for keyboard event forwarding
            window.panelViewModel = panelViewModel

            // Dismiss panel when user clicks outside
            window.onClickOutside = { [weak self] in
                self?.panelViewModel.dismiss()
            }

            panelWindow = window
        }

        guard let window = panelWindow else { return }

        // Increment generation so any in-flight hidePanel completion is invalidated
        panelShowHideGeneration += 1

        // Cancel any in-progress hide animation — snap to visible
        window.animator().alphaValue = 1.0
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

        panelShowHideGeneration += 1
        let hideGeneration = panelShowHideGeneration

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            window.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            // Only orderOut if no new show/hide has happened since we started
            guard let self, self.panelShowHideGeneration == hideGeneration else { return }
            window.orderOut(nil)
        })
    }

    // MARK: - Predictive Window Manager

    private func setupPredictiveWorkspace() {
        let screenCtx = ScreenContextProvider(
            installedAppRegistry: installedAppRegistry,
            taskStore: settings.enableTaskMode ? taskStore : nil
        )

        let predictor = WorkspacePredictor(
            workspaceLearner: workspaceLearner,
            installedAppRegistry: installedAppRegistry,
            interactionTracker: predictionEngine.interactionTracker,
            adaptiveWeightStore: settings.enablePersistentLearning ? adaptiveWeightStore : nil
        )

        let layoutEngine = SmartLayoutEngine(workspaceLearner: workspaceLearner)

        let handler = WorkspaceHotkeyHandler(
            screenContextProvider: screenCtx,
            predictor: predictor,
            layoutEngine: layoutEngine,
            panelViewModel: panelViewModel,
            interactionTracker: predictionEngine.interactionTracker,
            workspaceLearner: workspaceLearner
        )

        handler.onShowPanel = { [weak self] in
            self?.showPanel()
        }

        handler.onHidePanel = { [weak self] in
            self?.hidePanel()
        }

        self.workspaceHotkeyHandler = handler

        // Register Hyper+Space hotkey (Ctrl+Option+Shift+Cmd+Space)
        // Space keyCode = 49
        // Modifiers: control=0x1000, option=0x0800, shift=0x0200, cmd=0x0100
        let modifiers: UInt32 = UInt32(controlKey | optionKey | shiftKey | cmdKey)
        _ = windowManager.hotkeyManager.registerHotkey(
            keyCode: 49,
            modifiers: modifiers,
            action: { [weak handler] in
                handler?.handleHotkeyPress()
            }
        )

        Logger.app.info("Predictive window manager enabled (Hyper+Space)")
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
