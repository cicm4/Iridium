//
//  LayoutPresetStore.swift
//  Iridium
//

import Foundation
import Observation
import OSLog

@Observable
final class LayoutPresetStore {
    private let defaults: UserDefaults
    private static let key = "layoutPresets"

    private(set) var presets: [LayoutPreset] = []

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadPresets()
    }

    func addPreset(_ preset: LayoutPreset) {
        presets.append(preset)
        savePresets()
    }

    func removePreset(id: UUID) {
        presets.removeAll { $0.id == id }
        savePresets()
    }

    func updatePreset(_ preset: LayoutPreset) {
        guard let index = presets.firstIndex(where: { $0.id == preset.id }) else { return }
        presets[index] = preset
        savePresets()
    }

    private func loadPresets() {
        guard let data = defaults.data(forKey: Self.key),
              let decoded = try? JSONDecoder().decode([LayoutPreset].self, from: data)
        else {
            // Load defaults
            presets = [.leftHalf, .rightHalf, .fullscreen]
            return
        }
        presets = decoded
    }

    private func savePresets() {
        guard let data = try? JSONEncoder().encode(presets) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
