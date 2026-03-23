//
//  LayoutPreset.swift
//  Iridium
//

import Foundation

struct LayoutPreset: Codable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var regions: [Region]
    var hotkey: String?

    struct Region: Codable, Sendable, Equatable {
        /// Fractional position and size relative to screen (0.0-1.0).
        var x: Double
        var y: Double
        var width: Double
        var height: Double
    }

    static let leftHalf = LayoutPreset(
        id: UUID(),
        name: "Left Half",
        regions: [Region(x: 0, y: 0, width: 0.5, height: 1.0)],
        hotkey: "ctrl+opt+left"
    )

    static let rightHalf = LayoutPreset(
        id: UUID(),
        name: "Right Half",
        regions: [Region(x: 0.5, y: 0, width: 0.5, height: 1.0)],
        hotkey: "ctrl+opt+right"
    )

    static let fullscreen = LayoutPreset(
        id: UUID(),
        name: "Fullscreen",
        regions: [Region(x: 0, y: 0, width: 1.0, height: 1.0)],
        hotkey: "ctrl+opt+return"
    )

    static let leftThird = LayoutPreset(
        id: UUID(),
        name: "Left Third",
        regions: [Region(x: 0, y: 0, width: 0.333, height: 1.0)],
        hotkey: nil
    )

    static let centerThird = LayoutPreset(
        id: UUID(),
        name: "Center Third",
        regions: [Region(x: 0.333, y: 0, width: 0.334, height: 1.0)],
        hotkey: nil
    )

    static let rightThird = LayoutPreset(
        id: UUID(),
        name: "Right Third",
        regions: [Region(x: 0.667, y: 0, width: 0.333, height: 1.0)],
        hotkey: nil
    )
}
