//
//  PanelKeyboardTests.swift
//  IridiumTests
//
//  Tests that the SuggestionPanelWindow intercepts key events at the NSPanel
//  level (not SwiftUI .onKeyPress) so arrow keys, Enter, and Escape work
//  even when the panel uses .nonactivatingPanel style.
//

import AppKit
import Testing
@testable import Iridium

@MainActor
struct PanelKeyboardTests {

    // MARK: - NSPanel must handle keyDown directly

    @Test func panelHasKeyDownHandler() {
        // The panel must override keyDown to forward events to the view model,
        // because .nonActivatingPanel prevents SwiftUI .onKeyPress from firing.
        let panel = SuggestionPanelWindow()
        // Verify the panel has a viewModel property that can be set
        // (it needs a reference to forward key events)
        panel.panelViewModel = SuggestionPanelViewModel()
        #expect(panel.panelViewModel != nil)
    }

    @Test func downArrowKeyMovesSelectionDown() {
        let panel = SuggestionPanelWindow()
        let vm = SuggestionPanelViewModel()
        vm.configure(onSelection: { _ in }, onDismissal: { })
        let result = makeSuggestionResult()
        vm.show(result: result, autoDismissDelay: 10.0)
        panel.panelViewModel = vm

        #expect(vm.selectedIndex == 0)

        // Simulate down arrow key event
        let downArrow = makeKeyEvent(keyCode: 125, characters: NSDownArrowFunctionKey)
        panel.keyDown(with: downArrow)

        #expect(vm.selectedIndex == 1)
    }

    @Test func upArrowKeyMovesSelectionUp() {
        let panel = SuggestionPanelWindow()
        let vm = SuggestionPanelViewModel()
        vm.configure(onSelection: { _ in }, onDismissal: { })
        let result = makeSuggestionResult()
        vm.show(result: result, autoDismissDelay: 10.0)
        panel.panelViewModel = vm

        vm.moveSelectionDown() // go to index 1
        #expect(vm.selectedIndex == 1)

        let upArrow = makeKeyEvent(keyCode: 126, characters: NSUpArrowFunctionKey)
        panel.keyDown(with: upArrow)

        #expect(vm.selectedIndex == 0)
    }

    @Test func returnKeySelectsCurrent() {
        let panel = SuggestionPanelWindow()
        var selectedBundleID: String?
        let vm = SuggestionPanelViewModel()
        vm.configure(onSelection: { selectedBundleID = $0 }, onDismissal: { })
        let result = makeSuggestionResult()
        vm.show(result: result, autoDismissDelay: 10.0)
        panel.panelViewModel = vm

        let returnKey = makeKeyEvent(keyCode: 36, characters: "\r")
        panel.keyDown(with: returnKey)

        #expect(selectedBundleID == "com.apple.dt.Xcode")
        #expect(vm.isVisible == false)
    }

    @Test func escapeKeyDismisses() {
        let panel = SuggestionPanelWindow()
        var dismissed = false
        let vm = SuggestionPanelViewModel()
        vm.configure(onSelection: { _ in }, onDismissal: { dismissed = true })
        let result = makeSuggestionResult()
        vm.show(result: result, autoDismissDelay: 10.0)
        panel.panelViewModel = vm

        #expect(vm.isVisible == true)

        let escapeKey = makeKeyEvent(keyCode: 53, characters: "\u{1B}")
        panel.keyDown(with: escapeKey)

        #expect(vm.isVisible == false)
        #expect(dismissed == true)
    }

    @Test func multipleDownArrowsNavigateToEnd() {
        let panel = SuggestionPanelWindow()
        let vm = SuggestionPanelViewModel()
        vm.configure(onSelection: { _ in }, onDismissal: { })
        vm.show(result: makeSuggestionResult(), autoDismissDelay: 10.0)
        panel.panelViewModel = vm

        let downArrow = makeKeyEvent(keyCode: 125, characters: NSDownArrowFunctionKey)
        panel.keyDown(with: downArrow) // → 1
        panel.keyDown(with: downArrow) // → 2
        panel.keyDown(with: downArrow) // → 2 (clamped)

        #expect(vm.selectedIndex == 2)
    }

    @Test func downThenEnterSelectsCorrectSuggestion() {
        let panel = SuggestionPanelWindow()
        var selectedBundleID: String?
        let vm = SuggestionPanelViewModel()
        vm.configure(onSelection: { selectedBundleID = $0 }, onDismissal: { })
        vm.show(result: makeSuggestionResult(), autoDismissDelay: 10.0)
        panel.panelViewModel = vm

        let downArrow = makeKeyEvent(keyCode: 125, characters: NSDownArrowFunctionKey)
        panel.keyDown(with: downArrow) // → index 1 = VSCode

        let returnKey = makeKeyEvent(keyCode: 36, characters: "\r")
        panel.keyDown(with: returnKey)

        #expect(selectedBundleID == "com.microsoft.VSCode")
    }

    // MARK: - Helpers

    private func makeSuggestionResult() -> SuggestionResult {
        let suggestions = [
            Suggestion(bundleID: "com.apple.dt.Xcode", confidence: 0.95, sourcePackID: "test"),
            Suggestion(bundleID: "com.microsoft.VSCode", confidence: 0.90, sourcePackID: "test"),
            Suggestion(bundleID: "md.obsidian", confidence: 0.85, sourcePackID: "test"),
        ]
        return SuggestionResult(suggestions: suggestions, signal: ContextSignal())
    }

    private let NSUpArrowFunctionKey = "\u{F700}"
    private let NSDownArrowFunctionKey = "\u{F701}"

    private func makeKeyEvent(keyCode: UInt16, characters: String) -> NSEvent {
        NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: characters,
            charactersIgnoringModifiers: characters,
            isARepeat: false,
            keyCode: keyCode
        )!
    }
}
