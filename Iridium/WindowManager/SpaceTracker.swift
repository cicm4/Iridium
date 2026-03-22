//
//  SpaceTracker.swift
//  Iridium
//

import AppKit
import OSLog

@MainActor
final class SpaceTracker {
    private var observation: NSObjectProtocol?

    var onSpaceChange: (() -> Void)?

    func start() {
        observation = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                Logger.windowManager.debug("Active space changed")
                self?.onSpaceChange?()
            }
        }
    }

    func stop() {
        if let observation {
            NSWorkspace.shared.notificationCenter.removeObserver(observation)
        }
        observation = nil
    }
}
