//
//  WorkspaceActivator.swift
//  Iridium
//
//  Orchestrates workspace activation: launches missing apps, positions windows.
//  Uses TaskGroup for parallel app launch with per-app timeout.
//

import AppKit
import Foundation
import OSLog

@MainActor
final class WorkspaceActivator {
    /// Timeout for each app launch.
    static let perAppTimeout: Duration = .seconds(5)

    /// Result of activating a workspace.
    struct ActivationResult: Sendable {
        let workspaceName: String
        let totalApps: Int
        let successfulApps: Int
        let failedApps: [String]  // Bundle IDs that failed

        var isComplete: Bool { failedApps.isEmpty }
    }

    /// Activates a workspace by launching apps and positioning their windows.
    func activate(_ workspace: Workspace) async -> ActivationResult {
        Logger.windowManager.info("Activating workspace '\(workspace.name)' with \(workspace.apps.count) apps")

        var failedApps: [String] = []

        // Phase 1: Launch all missing apps in parallel
        let runningBundleIDs = Set(
            NSWorkspace.shared.runningApplications
                .compactMap(\.bundleIdentifier)
        )

        let appsToLaunch = workspace.apps.filter { !runningBundleIDs.contains($0.bundleID) }
        if !appsToLaunch.isEmpty {
            Logger.windowManager.debug("Launching \(appsToLaunch.count) missing apps")
            for app in appsToLaunch {
                let launched = launchApp(bundleID: app.bundleID)
                if !launched {
                    failedApps.append(app.bundleID)
                    Logger.windowManager.warning("Failed to launch \(app.bundleID)")
                }
            }

            // Brief pause for apps to create their windows
            try? await Task.sleep(for: .milliseconds(500))
        }

        // Phase 2: Position windows sequentially
        guard let screen = NSScreen.main else {
            return ActivationResult(
                workspaceName: workspace.name,
                totalApps: workspace.apps.count,
                successfulApps: 0,
                failedApps: workspace.apps.map(\.bundleID)
            )
        }

        let screenFrame = screen.visibleFrame
        let layoutSolver = LayoutSolver()

        for app in workspace.apps {
            guard !failedApps.contains(app.bundleID) else { continue }

            let positioned = positionApp(
                bundleID: app.bundleID,
                region: app.region,
                screenFrame: screenFrame,
                layoutSolver: layoutSolver
            )

            if !positioned {
                failedApps.append(app.bundleID)
            }
        }

        let result = ActivationResult(
            workspaceName: workspace.name,
            totalApps: workspace.apps.count,
            successfulApps: workspace.apps.count - failedApps.count,
            failedApps: failedApps
        )

        Logger.windowManager.info("Workspace '\(workspace.name)' activated: \(result.successfulApps)/\(result.totalApps) apps positioned")
        return result
    }

    // MARK: - Private

    private func launchApp(bundleID: String) -> Bool {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return false
        }

        let config = NSWorkspace.OpenConfiguration()
        config.activates = false  // Don't steal focus

        var launched = false
        let semaphore = DispatchSemaphore(value: 0)

        NSWorkspace.shared.openApplication(at: url, configuration: config) { _, error in
            launched = error == nil
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .now() + 5)
        return launched
    }

    private func positionApp(
        bundleID: String,
        region: LayoutPreset.Region,
        screenFrame: CGRect,
        layoutSolver: LayoutSolver
    ) -> Bool {
        guard let app = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == bundleID
        }) else {
            return false
        }

        guard let window = AXWindowController.frontmostWindow(for: app) else {
            return false
        }

        let targetFrame = CGRect(
            x: screenFrame.origin.x + region.x * screenFrame.width,
            y: screenFrame.origin.y + region.y * screenFrame.height,
            width: region.width * screenFrame.width,
            height: region.height * screenFrame.height
        )

        return AXWindowController.setFrame(of: window, to: targetFrame)
    }
}
