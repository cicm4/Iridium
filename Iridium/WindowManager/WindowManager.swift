//
//  WindowManager.swift
//  Iridium
//

import AppKit
import OSLog

@MainActor
final class WindowManager {
    private let layoutSolver = LayoutSolver()
    let presetStore = LayoutPresetStore()
    let spaceTracker = SpaceTracker()
    let hotkeyManager = HotkeyManager()

    private var isEnabled = false

    func start(accessibilityGranted: Bool) {
        guard accessibilityGranted else {
            Logger.windowManager.info("Window manager disabled: accessibility not granted")
            return
        }
        isEnabled = true
        spaceTracker.start()
        Logger.windowManager.info("Window manager started")
    }

    func stop() {
        isEnabled = false
        spaceTracker.stop()
        hotkeyManager.unregisterAll()
        Logger.windowManager.info("Window manager stopped")
    }

    /// Applies a layout preset to the frontmost window.
    func applyPreset(_ preset: LayoutPreset) {
        guard isEnabled else { return }
        guard let screen = NSScreen.main else { return }
        guard let app = NSWorkspace.shared.frontmostApplication else { return }
        guard let window = AXWindowController.frontmostWindow(for: app) else { return }

        let frames = layoutSolver.resolve(preset: preset, in: screen.visibleFrame)
        guard let frame = frames.first else { return }

        let success = AXWindowController.setFrame(of: window, to: frame)
        if success {
            ToastManager.shared.show("Window snapped to \(preset.name)", icon: "rectangle.split.2x1")
        }
        Logger.windowManager.debug("Applied preset '\(preset.name)': \(success ? "success" : "failed")")
    }

    /// Tiles the frontmost window to the left half.
    func tileLeft() {
        applyPreset(.leftHalf)
    }

    /// Tiles the frontmost window to the right half.
    func tileRight() {
        applyPreset(.rightHalf)
    }

    /// Maximizes the frontmost window.
    func maximize() {
        applyPreset(.fullscreen)
    }
}
