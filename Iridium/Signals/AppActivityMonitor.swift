//
//  AppActivityMonitor.swift
//  Iridium
//

import AppKit
import OSLog

@MainActor
final class AppActivityMonitor: SignalProvider {
    private(set) var currentBundleID: String?
    private var observation: NSObjectProtocol?
    private var onChange: ((String) -> Void)?

    nonisolated init() {}

    func onAppChange(_ handler: @escaping (String) -> Void) {
        self.onChange = handler
    }

    func start() {
        stop()
        currentBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        observation = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            MainActor.assumeIsolated {
                self?.handleAppActivation(notification)
            }
        }
    }

    func stop() {
        if let observation {
            NSWorkspace.shared.notificationCenter.removeObserver(observation)
        }
        observation = nil
        currentBundleID = nil
    }

    private func handleAppActivation(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleID = app.bundleIdentifier else { return }

        currentBundleID = bundleID
        Logger.signals.debug("App activated: \(bundleID, privacy: .public)")
        onChange?(bundleID)
    }
}
