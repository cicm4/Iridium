//
//  WorkspaceHotkeyHandlerTests.swift
//  IridiumTests
//

import Testing
@testable import Iridium

@MainActor
struct WorkspaceHotkeyHandlerTests {
    private func makeHandler() -> (WorkspaceHotkeyHandler, SuggestionPanelViewModel, TestScreenContextProvider) {
        let registry = InstalledAppRegistry()
        let learner = WorkspaceLearner()
        let contextProvider = TestScreenContextProvider(installedAppRegistry: registry)
        let predictor = WorkspacePredictor(
            workspaceLearner: learner,
            installedAppRegistry: registry
        )
        let layoutEngine = SmartLayoutEngine(workspaceLearner: learner)
        let panelVM = SuggestionPanelViewModel()

        let handler = WorkspaceHotkeyHandler(
            screenContextProvider: contextProvider,
            predictor: predictor,
            layoutEngine: layoutEngine,
            panelViewModel: panelVM,
            workspaceLearner: learner
        )

        return (handler, panelVM, contextProvider)
    }

    @Test("Full pipeline: hotkey press shows suggestions in panel")
    func fullPredictionPipeline() {
        let (handler, panelVM, contextProvider) = makeHandler()

        contextProvider.mockContext = ScreenContext(
            runningApps: [
                RunningAppInfo(bundleID: "com.apple.dt.Xcode", name: "Xcode", isActive: true, category: .development),
                RunningAppInfo(bundleID: "com.apple.Terminal", name: "Terminal", isActive: false, category: .development),
                RunningAppInfo(bundleID: "com.apple.Safari", name: "Safari", isActive: false, category: .research),
            ],
            frontmostBundleID: "com.apple.dt.Xcode",
            frontmostWindowTitle: "main.swift",
            windowLayout: [],
            hourOfDay: 14,
            displayCount: 1,
            activeTaskName: nil,
            activeTaskCategories: nil,
            clipboardContentType: nil,
            timestamp: .now
        )

        panelVM.configure(onSelection: { _ in }, onDismissal: {})

        handler.handleHotkeyPress()

        #expect(panelVM.isVisible, "Panel should be visible after hotkey press")
        #expect(!panelVM.suggestions.isEmpty, "Panel should have suggestions")
        #expect(handler.isActive, "Handler should be in active state")
    }

    @Test("No suggestions does not show panel")
    func noSuggestionsDoesNotShowPanel() {
        let (handler, panelVM, contextProvider) = makeHandler()

        // Only frontmost app, nothing in background
        contextProvider.mockContext = ScreenContext(
            runningApps: [
                RunningAppInfo(bundleID: "com.apple.dt.Xcode", name: "Xcode", isActive: true, category: .development),
            ],
            frontmostBundleID: "com.apple.dt.Xcode",
            frontmostWindowTitle: nil,
            windowLayout: [],
            hourOfDay: 14,
            displayCount: 1,
            activeTaskName: nil,
            activeTaskCategories: nil,
            clipboardContentType: nil,
            timestamp: .now
        )

        panelVM.configure(onSelection: { _ in }, onDismissal: {})

        handler.handleHotkeyPress()

        #expect(!panelVM.isVisible, "Panel should not show when no suggestions")
        #expect(!handler.isActive, "Handler should not be active")
    }

    @Test("Dismissal resets handler state")
    func dismissalResetsState() {
        let (handler, panelVM, contextProvider) = makeHandler()

        contextProvider.mockContext = ScreenContext(
            runningApps: [
                RunningAppInfo(bundleID: "com.apple.dt.Xcode", name: "Xcode", isActive: true, category: .development),
                RunningAppInfo(bundleID: "com.apple.Terminal", name: "Terminal", isActive: false, category: .development),
            ],
            frontmostBundleID: "com.apple.dt.Xcode",
            frontmostWindowTitle: nil,
            windowLayout: [],
            hourOfDay: 14,
            displayCount: 1,
            activeTaskName: nil,
            activeTaskCategories: nil,
            clipboardContentType: nil,
            timestamp: .now
        )

        panelVM.configure(onSelection: { _ in }, onDismissal: {})

        handler.handleHotkeyPress()
        #expect(handler.isActive)

        handler.handleDismissal()
        #expect(!handler.isActive, "Handler should be inactive after dismissal")
    }
}

// MARK: - Test Helper

/// A ScreenContextProvider subclass that returns mock data for testing.
@MainActor
final class TestScreenContextProvider: ScreenContextProvider {
    var mockContext: ScreenContext?

    override func collectContext() -> ScreenContext {
        if let mock = mockContext { return mock }
        return super.collectContext()
    }
}
