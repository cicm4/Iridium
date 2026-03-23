//
//  ScreenContextProvider.swift
//  Iridium
//
//  Collects current screen state for predictive window management.
//  Must complete in <20ms for responsive hotkey handling.
//

import AppKit
import CoreGraphics
import OSLog

struct RunningAppInfo: Sendable {
    let bundleID: String
    let name: String
    let isActive: Bool
    let category: AppCategory
}

struct WindowSnapshot: Sendable {
    let ownerBundleID: String
    let title: String
    let frame: CGRect
    let isOnScreen: Bool
    let screenIndex: Int
}

struct ScreenContext: Sendable {
    let runningApps: [RunningAppInfo]
    let frontmostBundleID: String?
    let frontmostWindowTitle: String?
    let windowLayout: [WindowSnapshot]
    let hourOfDay: Int
    let displayCount: Int
    let activeTaskName: String?
    let activeTaskCategories: [AppCategory: Double]?
    let clipboardContentType: ContentType?
    let timestamp: ContinuousClock.Instant

    /// Bundle IDs of all background (non-frontmost) running apps.
    var backgroundAppBundleIDs: Set<String> {
        Set(runningApps.filter { !$0.isActive }.map(\.bundleID))
    }
}

@MainActor
class ScreenContextProvider {
    private let installedAppRegistry: InstalledAppRegistry
    private let taskStore: TaskStore?

    init(installedAppRegistry: InstalledAppRegistry, taskStore: TaskStore? = nil) {
        self.installedAppRegistry = installedAppRegistry
        self.taskStore = taskStore
    }

    /// Collects the current screen context synchronously. Target: <20ms.
    func collectContext() -> ScreenContext {
        let frontmostApp = NSWorkspace.shared.frontmostApplication
        let frontmostBundleID = frontmostApp?.bundleIdentifier

        // Running apps (regular activation policy only)
        let runningApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app -> RunningAppInfo? in
                guard let bundleID = app.bundleIdentifier else { return nil }
                return RunningAppInfo(
                    bundleID: bundleID,
                    name: app.localizedName ?? bundleID,
                    isActive: bundleID == frontmostBundleID,
                    category: installedAppRegistry.category(for: bundleID)
                )
            }

        // Window title from accessibility (best effort)
        let frontmostWindowTitle = readFrontmostWindowTitle(for: frontmostApp)

        // Window layout from CGWindowList
        let windowLayout = readWindowLayout()

        // Task context
        let activeTask = taskStore?.activeTask
        let taskCategories = activeTask?.resolvedCategories

        return ScreenContext(
            runningApps: runningApps,
            frontmostBundleID: frontmostBundleID,
            frontmostWindowTitle: frontmostWindowTitle,
            windowLayout: windowLayout,
            hourOfDay: Calendar.current.component(.hour, from: Date()),
            displayCount: NSScreen.screens.count,
            activeTaskName: activeTask?.name,
            activeTaskCategories: taskCategories,
            clipboardContentType: nil, // filled by caller if needed
            timestamp: .now
        )
    }

    // MARK: - Private

    private func readFrontmostWindowTitle(for app: NSRunningApplication?) -> String? {
        guard let app else { return nil }
        guard let window = AXWindowController.frontmostWindow(for: app) else { return nil }

        var titleValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleValue)
        guard result == .success, let title = titleValue as? String else { return nil }
        return title
    }

    private func readWindowLayout() -> [WindowSnapshot] {
        guard let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        var snapshots: [WindowSnapshot] = []
        let runningApps = NSWorkspace.shared.runningApplications

        for info in windowList {
            guard let layer = info[kCGWindowLayer as String] as? Int, layer == 0 else { continue }
            guard let pid = info[kCGWindowOwnerPID as String] as? pid_t else { continue }
            guard let bounds = info[kCGWindowBounds as String] as? [String: CGFloat] else { continue }

            let app = runningApps.first { $0.processIdentifier == pid }
            guard let bundleID = app?.bundleIdentifier else { continue }
            guard app?.activationPolicy == .regular else { continue }

            let title = info[kCGWindowName as String] as? String ?? ""
            let frame = CGRect(
                x: bounds["X"] ?? 0,
                y: bounds["Y"] ?? 0,
                width: bounds["Width"] ?? 0,
                height: bounds["Height"] ?? 0
            )

            // Determine which screen this window is on
            let screenIndex = NSScreen.screens.firstIndex { screen in
                screen.frame.contains(CGPoint(x: frame.midX, y: frame.midY))
            } ?? 0

            snapshots.append(WindowSnapshot(
                ownerBundleID: bundleID,
                title: title,
                frame: frame,
                isOnScreen: true,
                screenIndex: screenIndex
            ))
        }

        return snapshots
    }
}
