//
//  TilingOverlayController.swift
//  Iridium
//

import AppKit

@MainActor
final class TilingOverlayController {
    private var overlayWindow: TilingOverlayWindow?
    private let windowManager: WindowManager

    init(windowManager: WindowManager) {
        self.windowManager = windowManager
    }

    var isVisible: Bool { overlayWindow != nil }

    func toggle() {
        if isVisible {
            dismiss()
        } else {
            show()
        }
    }

    func show() {
        guard overlayWindow == nil else { return }
        guard let screen = NSScreen.main else { return }

        let presets = windowManager.presetStore.presets
        guard !presets.isEmpty else { return }

        let overlay = TilingOverlayWindow(
            presets: presets,
            screenFrame: screen.visibleFrame
        )

        overlay.onSelectPreset = { [weak self] preset in
            self?.windowManager.applyPreset(preset)
            self?.dismiss()
        }

        overlay.onDismiss = { [weak self] in
            self?.dismiss()
        }

        overlay.alphaValue = 0
        overlay.orderFrontRegardless()
        overlay.makeKey()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            overlay.animator().alphaValue = 1.0
        }

        self.overlayWindow = overlay
    }

    func dismiss() {
        guard let overlay = overlayWindow else { return }
        self.overlayWindow = nil

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            overlay.animator().alphaValue = 0
        }, completionHandler: {
            overlay.orderOut(nil)
        })
    }
}
