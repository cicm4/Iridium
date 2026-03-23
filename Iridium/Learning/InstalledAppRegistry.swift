//
//  InstalledAppRegistry.swift
//  Iridium
//
//  Scans /Applications and ~/Applications at launch, caches bundle IDs,
//  and provides app metadata (category, name). Replaces scattered
//  NSWorkspace.urlForApplication() calls with a precomputed set.
//

import AppKit
import Foundation
import OSLog

@Observable
final class InstalledAppRegistry: @unchecked Sendable {
    struct AppInfo: Sendable {
        let bundleID: String
        let name: String
        let category: AppCategory
        let url: URL
    }

    /// All discovered installed apps, keyed by bundle ID.
    private(set) var apps: [String: AppInfo] = [:]

    /// Bundle IDs of currently running user apps.
    private(set) var runningAppBundleIDs: Set<String> = []

    /// How many times each app has been launched during this session.
    private(set) var launchCounts: [String: Int] = [:]

    private var workspaceObserver: NSObjectProtocol?

    /// Whether the registry has completed its initial scan.
    private(set) var isReady = false

    /// Returns whether a bundle ID corresponds to an installed app.
    func isInstalled(_ bundleID: String) -> Bool {
        apps[bundleID] != nil
    }

    /// Returns the category for a bundle ID.
    func category(for bundleID: String) -> AppCategory {
        apps[bundleID]?.category ?? AppCategory.from(bundleID: bundleID)
    }

    /// Returns the display name for a bundle ID.
    func name(for bundleID: String) -> String? {
        apps[bundleID]?.name
    }

    /// Scans /Applications and ~/Applications for installed apps.
    /// Should be called on a background thread.
    func scan() {
        let searchPaths = [
            URL(fileURLWithPath: "/Applications"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications"),
        ]

        var discovered: [String: AppInfo] = [:]

        for searchPath in searchPaths {
            scanDirectory(searchPath, into: &discovered, depth: 2)
        }

        apps = discovered
        isReady = true
        Logger.learning.info("Installed app scan complete: \(discovered.count) apps found")
    }

    /// Starts observing app launches to track running apps.
    @MainActor
    func startObservingLaunches() {
        updateRunningApps()

        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let bundleID = app.bundleIdentifier
            else { return }
            self?.launchCounts[bundleID, default: 0] += 1
            self?.updateRunningApps()
            Logger.learning.debug("App launched: \(bundleID)")
        }

        // Also observe terminations to keep runningAppBundleIDs current
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateRunningApps()
        }
    }

    /// Stops observing app launches.
    func stopObservingLaunches() {
        if let observer = workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            workspaceObserver = nil
        }
    }

    // MARK: - Private

    @MainActor
    private func updateRunningApps() {
        runningAppBundleIDs = Set(
            NSWorkspace.shared.runningApplications
                .filter { $0.activationPolicy == .regular }
                .compactMap(\.bundleIdentifier)
        )
    }

    private func scanDirectory(_ url: URL, into results: inout [String: AppInfo], depth: Int) {
        guard depth > 0 else { return }
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        for item in contents {
            if item.pathExtension == "app" {
                if let info = appInfo(from: item) {
                    results[info.bundleID] = info
                }
            } else if item.hasDirectoryPath {
                // Recurse into subdirectories (e.g., /Applications/Utilities/)
                scanDirectory(item, into: &results, depth: depth - 1)
            }
        }
    }

    private func appInfo(from appURL: URL) -> AppInfo? {
        guard let bundle = Bundle(url: appURL),
              let bundleID = bundle.bundleIdentifier
        else { return nil }

        let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? appURL.deletingPathExtension().lastPathComponent

        let lsCategoryType = bundle.object(forInfoDictionaryKey: "LSApplicationCategoryType") as? String
        let category = lsCategoryType != nil
            ? AppCategory.from(lsCategoryType: lsCategoryType)
            : AppCategory.from(bundleID: bundleID)

        return AppInfo(
            bundleID: bundleID,
            name: name,
            category: category,
            url: appURL
        )
    }
}
