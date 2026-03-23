//
//  SuggestionPanelWindowTests.swift
//  IridiumTests
//
//  Tests for the SuggestionPanelWindow — focus behavior, activation,
//  click-outside dismissal, and panel level.
//

import AppKit
import Testing
@testable import Iridium

@MainActor
struct SuggestionPanelWindowTests {

    // MARK: - Panel Must Accept Key Events (Focus Fix)

    @Test func panelCanBecomeKey() {
        let panel = SuggestionPanelWindow()
        // Panel MUST accept keyboard focus so arrow keys/enter/escape work
        #expect(panel.canBecomeKey == true)
    }

    @Test func panelCannotBecomeMain() {
        let panel = SuggestionPanelWindow()
        // Panel must NOT steal main window status from other apps
        #expect(panel.canBecomeMain == false)
    }

    @Test func panelIsFloating() {
        let panel = SuggestionPanelWindow()
        #expect(panel.level == .floating)
    }

    @Test func panelIsTransparent() {
        let panel = SuggestionPanelWindow()
        #expect(panel.isOpaque == false)
        #expect(panel.backgroundColor == .clear)
    }

    @Test func panelDoesNotHideOnDeactivate() {
        let panel = SuggestionPanelWindow()
        #expect(panel.hidesOnDeactivate == false)
    }

    @Test func panelHasShadow() {
        let panel = SuggestionPanelWindow()
        #expect(panel.hasShadow == true)
    }

    @Test func panelJoinsAllSpaces() {
        let panel = SuggestionPanelWindow()
        #expect(panel.collectionBehavior.contains(.canJoinAllSpaces))
    }

    @Test func panelIsStationary() {
        let panel = SuggestionPanelWindow()
        // Stationary = hidden in Expose/Mission Control
        #expect(panel.collectionBehavior.contains(.stationary))
    }

    // MARK: - Panel Activation Behavior (Critical Fix)
    // The panel must make itself key AND activate the app briefly so clicks register

    @Test func panelAcceptsMouseEvents() {
        let panel = SuggestionPanelWindow()
        // acceptsMouseMovedEvents should be enabled for hover states
        #expect(panel.acceptsMouseMovedEvents == true)
    }

    @Test func panelIgnoresMouseEventsIsFalse() {
        let panel = SuggestionPanelWindow()
        // ignoresMouseEvents must be false so clicks on suggestions work
        #expect(panel.ignoresMouseEvents == false)
    }
}
