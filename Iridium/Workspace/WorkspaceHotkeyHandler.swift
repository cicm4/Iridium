//
//  WorkspaceHotkeyHandler.swift
//  Iridium
//
//  Orchestrates the predictive window manager flow:
//  hotkey → collect context → predict → show panel → arrange on selection.
//

import AppKit
import Foundation
import OSLog

@MainActor
final class WorkspaceHotkeyHandler {
    private let screenContextProvider: ScreenContextProvider
    private let predictor: WorkspacePredictor
    private let layoutEngine: SmartLayoutEngine
    private let panelViewModel: SuggestionPanelViewModel
    private let interactionTracker: InteractionTracker?
    private let workspaceLearner: WorkspaceLearner

    /// Whether the handler has an active prediction session.
    private(set) var isActive = false

    /// The last collected context (used for layout on selection).
    private var lastContext: ScreenContext?

    /// Callback to show the suggestion panel.
    var onShowPanel: (() -> Void)?

    /// Callback to hide the suggestion panel.
    var onHidePanel: (() -> Void)?

    init(
        screenContextProvider: ScreenContextProvider,
        predictor: WorkspacePredictor,
        layoutEngine: SmartLayoutEngine,
        panelViewModel: SuggestionPanelViewModel,
        interactionTracker: InteractionTracker? = nil,
        workspaceLearner: WorkspaceLearner
    ) {
        self.screenContextProvider = screenContextProvider
        self.predictor = predictor
        self.layoutEngine = layoutEngine
        self.panelViewModel = panelViewModel
        self.interactionTracker = interactionTracker
        self.workspaceLearner = workspaceLearner
    }

    /// Called when the workspace hotkey is pressed.
    func handleHotkeyPress() {
        let context = screenContextProvider.collectContext()
        let suggestions = predictor.predict(context: context)

        guard !suggestions.isEmpty else {
            Logger.windowManager.debug("No predictions available for current context")
            return
        }

        lastContext = context
        isActive = true

        let result = SuggestionResult(
            suggestions: suggestions,
            signal: synthesizeSignal(from: context)
        )

        panelViewModel.show(result: result, autoDismissDelay: 10.0)
        onShowPanel?()

        Logger.windowManager.info("Workspace prediction: \(suggestions.count) suggestions")
    }

    /// Called when the user selects a suggestion from the workspace prediction.
    func handleSelection(bundleID: String) async {
        guard let context = lastContext else { return }

        let result = await layoutEngine.activateAndArrange(
            bundleID: bundleID,
            context: context
        )

        interactionTracker?.recordSelection(bundleID: bundleID)
        workspaceLearner.recordAppSwitch(to: bundleID)

        // Record co-activation for all running apps
        let runningBundleIDs = Set(context.runningApps.map(\.bundleID))
        workspaceLearner.recordCoActivation(runningApps: runningBundleIDs)

        isActive = false
        lastContext = nil

        Logger.windowManager.info("Workspace selection: \(bundleID) arranged=\(result.applied)")
    }

    /// Called when the user dismisses without selecting.
    func handleDismissal() {
        isActive = false
        lastContext = nil
    }

    // MARK: - Private

    private func synthesizeSignal(from context: ScreenContext) -> ContextSignal {
        ContextSignal(
            clipboardUTI: nil,
            clipboardSample: nil,
            contentType: context.clipboardContentType,
            language: nil,
            frontmostAppBundleID: context.frontmostBundleID,
            hourOfDay: context.hourOfDay,
            displayCount: context.displayCount,
            focusModeActive: false,
            timestamp: context.timestamp,
            windowTitle: context.frontmostWindowTitle,
            screenContentSample: nil,
            activeFileExtensions: nil,
            upcomingMeetingInMinutes: nil,
            browserDomain: nil,
            browserTabTitle: nil,
            clipboardPatternHint: nil,
            integrationSignals: nil
        )
    }
}
