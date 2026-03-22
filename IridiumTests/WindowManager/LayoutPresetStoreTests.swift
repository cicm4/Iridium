//
//  LayoutPresetStoreTests.swift
//  IridiumTests
//

import Testing
import Foundation
@testable import Iridium

@MainActor
struct LayoutPresetStoreTests {
    // MARK: - Default Presets

    @Test func loadsDefaultPresets() {
        let defaults = UserDefaults(suiteName: "test.presets.\(UUID().uuidString)")!
        let store = LayoutPresetStore(defaults: defaults)
        #expect(store.presets.count == 3)
        let names = store.presets.map(\.name)
        #expect(names.contains("Left Half"))
        #expect(names.contains("Right Half"))
        #expect(names.contains("Fullscreen"))
    }

    // MARK: - Add Preset

    @Test func addPresetPersists() {
        let suiteName = "test.presets.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let store = LayoutPresetStore(defaults: defaults)
        let newPreset = LayoutPreset(
            id: UUID(),
            name: "Top Half",
            regions: [LayoutPreset.Region(x: 0, y: 0, width: 1.0, height: 0.5)],
            hotkey: nil
        )
        store.addPreset(newPreset)

        #expect(store.presets.count == 4)

        // Verify persistence by creating a new store with same defaults
        let store2 = LayoutPresetStore(defaults: defaults)
        #expect(store2.presets.count == 4)
        #expect(store2.presets.last?.name == "Top Half")
    }

    // MARK: - Remove Preset

    @Test func removePreset() {
        let defaults = UserDefaults(suiteName: "test.presets.\(UUID().uuidString)")!
        let store = LayoutPresetStore(defaults: defaults)
        let idToRemove = store.presets[0].id
        store.removePreset(id: idToRemove)
        #expect(store.presets.count == 2)
        #expect(!store.presets.contains(where: { $0.id == idToRemove }))
    }

    // MARK: - Update Preset

    @Test func updatePresetName() {
        let defaults = UserDefaults(suiteName: "test.presets.\(UUID().uuidString)")!
        let store = LayoutPresetStore(defaults: defaults)
        var preset = store.presets[0]
        preset.name = "Updated Name"
        store.updatePreset(preset)
        #expect(store.presets[0].name == "Updated Name")
    }
}
