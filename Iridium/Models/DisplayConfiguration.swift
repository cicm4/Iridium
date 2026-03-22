//
//  DisplayConfiguration.swift
//  Iridium
//

import AppKit

struct DisplayConfiguration: Sendable {
    let screens: [ScreenInfo]

    struct ScreenInfo: Sendable {
        let frame: CGRect
        let visibleFrame: CGRect
        let isMain: Bool
    }

    @MainActor
    static var current: DisplayConfiguration {
        DisplayConfiguration(
            screens: NSScreen.screens.map { screen in
                ScreenInfo(
                    frame: screen.frame,
                    visibleFrame: screen.visibleFrame,
                    isMain: screen == NSScreen.main
                )
            }
        )
    }
}
