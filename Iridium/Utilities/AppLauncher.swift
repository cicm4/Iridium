//
//  AppLauncher.swift
//  Iridium
//

import AppKit
import OSLog

struct AppLauncher {
    @MainActor
    static func launch(bundleID: String) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            Logger.app.warning("Cannot find app for bundle ID: \(bundleID)")
            return
        }

        NSWorkspace.shared.openApplication(
            at: url,
            configuration: NSWorkspace.OpenConfiguration()
        ) { app, error in
            if let error {
                Logger.app.error("Failed to launch \(bundleID): \(error.localizedDescription)")
            } else {
                Logger.app.debug("Launched \(bundleID)")
            }
        }
    }
}
