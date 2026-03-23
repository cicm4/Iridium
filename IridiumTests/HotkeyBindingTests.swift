//
//  HotkeyBindingTests.swift
//  IridiumTests
//

import Testing
import Foundation
import Carbon
@testable import Iridium

@MainActor
struct HotkeyBindingTests {
    private func makeStore() -> SettingsStore {
        let defaults = UserDefaults(suiteName: "test.hotkeys.\(UUID().uuidString)")!
        return SettingsStore(defaults: defaults)
    }

    // MARK: - Codable Round-Trip

    @Test func hotkeyBindingCodableRoundTrip() throws {
        let binding = HotkeyBinding(
            action: .tileLeft,
            keyCode: 123,
            modifiers: UInt32(controlKey | optionKey)
        )
        let data = try JSONEncoder().encode(binding)
        let decoded = try JSONDecoder().decode(HotkeyBinding.self, from: data)
        #expect(decoded == binding)
        #expect(decoded.action == .tileLeft)
        #expect(decoded.keyCode == 123)
    }

    // MARK: - Display String

    @Test func displayStringShowsModifiersAndKey() {
        let binding = HotkeyBinding(
            action: .maximize,
            keyCode: 36,
            modifiers: UInt32(controlKey | optionKey)
        )
        let display = binding.displayString
        #expect(display.contains("\u{2303}")) // Control
        #expect(display.contains("\u{2325}")) // Option
        #expect(display.contains("\u{21A9}")) // Return
    }

    @Test func displayStringHyperSpace() {
        let binding = HotkeyAction.workspacePredict.defaultBinding
        let display = binding.displayString
        #expect(display.contains("Space"))
        #expect(display.contains("\u{2303}"))
        #expect(display.contains("\u{2325}"))
        #expect(display.contains("\u{21E7}"))
        #expect(display.contains("\u{2318}"))
    }

    // MARK: - Settings Store Integration

    @Test func defaultBindingsMatchAllActions() {
        let store = makeStore()
        for action in HotkeyAction.allCases {
            let binding = store.binding(for: action)
            #expect(binding.action == action)
            #expect(binding == action.defaultBinding)
        }
    }

    @Test func updateBindingPersists() {
        let suiteName = "test.hotkeys.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let store = SettingsStore(defaults: defaults)

        store.updateBinding(for: .tileLeft, keyCode: 0, modifiers: UInt32(cmdKey | shiftKey))

        let store2 = SettingsStore(defaults: defaults)
        let binding = store2.binding(for: .tileLeft)
        #expect(binding.keyCode == 0)
        #expect(binding.modifiers == UInt32(cmdKey | shiftKey))
    }

    @Test func conflictDetectionFindsClash() {
        let store = makeStore()
        let existing = store.binding(for: .tileLeft)
        let conflict = store.conflictingAction(
            keyCode: existing.keyCode,
            modifiers: existing.modifiers,
            excluding: .maximize
        )
        #expect(conflict == .tileLeft)
    }

    @Test func conflictDetectionIgnoresExcludedAction() {
        let store = makeStore()
        let existing = store.binding(for: .tileLeft)
        let conflict = store.conflictingAction(
            keyCode: existing.keyCode,
            modifiers: existing.modifiers,
            excluding: .tileLeft
        )
        #expect(conflict == nil)
    }

    @Test func conflictDetectionReturnsNilForUniqueBinding() {
        let store = makeStore()
        let conflict = store.conflictingAction(
            keyCode: 99,
            modifiers: UInt32(cmdKey),
            excluding: .tileLeft
        )
        #expect(conflict == nil)
    }

    // MARK: - All Actions Have Defaults

    @Test func everyActionHasDefaultBinding() {
        for action in HotkeyAction.allCases {
            let binding = action.defaultBinding
            #expect(binding.action == action)
            #expect(binding.modifiers != 0)
        }
    }

    @Test func defaultBindingsAreUnique() {
        let defaults = HotkeyAction.allCases.map(\.defaultBinding)
        let keys = defaults.map { "\($0.keyCode)-\($0.modifiers)" }
        #expect(Set(keys).count == keys.count)
    }
}
