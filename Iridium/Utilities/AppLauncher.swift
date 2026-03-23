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

    @MainActor
    static func openURL(_ urlString: String, inApp bundleID: String) {
        guard let url = URL(string: urlString) ?? URL(string: "https://\(urlString)") else {
            Logger.app.warning("Invalid URL: \(urlString)")
            return
        }
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            Logger.app.warning("Cannot find app for bundle ID: \(bundleID)")
            return
        }

        let config = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: config) { _, error in
            if let error {
                Logger.app.error("Failed to open URL in \(bundleID): \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    static func openFile(_ path: String, inApp bundleID: String) {
        let fileURL = URL(fileURLWithPath: path)
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            Logger.app.warning("Cannot find app for bundle ID: \(bundleID)")
            return
        }

        let config = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.open([fileURL], withApplicationAt: appURL, configuration: config) { _, error in
            if let error {
                Logger.app.error("Failed to open file in \(bundleID): \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    static func revealInFinder(_ path: String) {
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
