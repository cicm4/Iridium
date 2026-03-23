//
//  SmartLayoutEngine.swift
//  Iridium
//
//  Intelligent window arrangement: brings apps to front and positions them
//  optimally relative to existing windows. Learns preferred layouts.
//

import AppKit
import OSLog

@MainActor
final class SmartLayoutEngine {
    private let layoutSolver = LayoutSolver()
    private let workspaceLearner: WorkspaceLearner

    struct ArrangementResult: Sendable {
        let bundleID: String
        let applied: Bool
        let region: LayoutPreset.Region
    }

    init(workspaceLearner: WorkspaceLearner) {
        self.workspaceLearner = workspaceLearner
    }

    /// Brings an app to front and positions it optimally.
    func activateAndArrange(
        bundleID: String,
        context: ScreenContext
    ) async -> ArrangementResult {
        let runningApp = NSWorkspace.shared.runningApplications.first {
            $0.bundleIdentifier == bundleID
        }

        var app = runningApp

        // Launch if not running
        if app == nil {
            app = await launchApp(bundleID: bundleID)
        }

        guard let targetApp = app else {
            Logger.windowManager.error("Failed to launch or find app: \(bundleID)")
            return ArrangementResult(bundleID: bundleID, applied: false, region: .rightHalf)
        }

        // Activate the app (bring to front)
        targetApp.activate()

        // Wait briefly for the window to become available
        let window = await waitForWindow(app: targetApp, timeout: 3.0)

        guard let targetWindow = window else {
            Logger.windowManager.debug("No window available for \(bundleID), activation only")
            return ArrangementResult(bundleID: bundleID, applied: false, region: .rightHalf)
        }

        // Determine optimal region
        let frontmostBundleID = context.frontmostBundleID ?? ""
        let region = determineOptimalRegion(
            for: bundleID,
            relativeTo: frontmostBundleID,
            context: context
        )

        // Apply the layout
        guard let screen = NSScreen.main else {
            return ArrangementResult(bundleID: bundleID, applied: false, region: region)
        }

        let screenFrame = screen.visibleFrame
        let targetFrame = resolveRegion(region, in: screenFrame)
        let success = AXWindowController.setFrame(of: targetWindow, to: targetFrame)

        // Record the layout choice for learning
        if success {
            workspaceLearner.recordLayoutChoice(
                appA: frontmostBundleID,
                regionA: complementRegion(of: region),
                appB: bundleID,
                regionB: region
            )
        }

        Logger.windowManager.debug("Arranged \(bundleID) to \(String(describing: region)): \(success)")
        return ArrangementResult(bundleID: bundleID, applied: success, region: region)
    }

    /// Determines the best region for a new window.
    func determineOptimalRegion(
        for targetBundleID: String,
        relativeTo frontmostBundleID: String,
        context: ScreenContext
    ) -> LayoutPreset.Region {
        // 1. Check learned layout preferences (need ≥3 uses)
        if let learned = workspaceLearner.preferredLayout(forPair: frontmostBundleID, targetBundleID),
           learned.count >= 3 {
            return learned.regionB
        }

        // 2. Heuristic: look at existing window layout
        guard let screen = NSScreen.main else { return .rightHalf }
        let screenFrame = screen.visibleFrame

        let visibleWindows = context.windowLayout.filter { $0.isOnScreen }

        // If one window occupies >60% of screen width, place on opposite side
        if let mainWindow = visibleWindows.first(where: { $0.ownerBundleID == frontmostBundleID }) {
            let widthRatio = mainWindow.frame.width / screenFrame.width
            if widthRatio > 0.6 {
                // Is the main window more on the left or right?
                let midX = mainWindow.frame.midX
                let screenMidX = screenFrame.midX
                return midX < screenMidX ? .rightHalf : .leftHalf
            }
        }

        // 3. Find the emptiest region
        return findBestRegion(
            excluding: visibleWindows.map(\.frame),
            in: screenFrame
        )
    }

    // MARK: - Private

    private func launchApp(bundleID: String) async -> NSRunningApplication? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }

        let config = NSWorkspace.OpenConfiguration()
        config.activates = true

        do {
            let app = try await NSWorkspace.shared.openApplication(at: url, configuration: config)
            return app
        } catch {
            Logger.windowManager.error("Failed to launch \(bundleID): \(error)")
            return nil
        }
    }

    private func waitForWindow(app: NSRunningApplication, timeout: TimeInterval) async -> AXUIElement? {
        let deadline = ContinuousClock.now + .seconds(timeout)
        let pollInterval = Duration.milliseconds(100)

        while ContinuousClock.now < deadline {
            if let window = AXWindowController.frontmostWindow(for: app) {
                return window
            }
            try? await Task.sleep(for: pollInterval)
        }

        return nil
    }

    private func resolveRegion(_ region: LayoutPreset.Region, in screenFrame: CGRect) -> CGRect {
        CGRect(
            x: screenFrame.origin.x + region.x * screenFrame.width,
            y: screenFrame.origin.y + region.y * screenFrame.height,
            width: region.width * screenFrame.width,
            height: region.height * screenFrame.height
        )
    }

    /// Finds the region with least overlap with existing windows.
    func findBestRegion(
        excluding occupiedFrames: [CGRect],
        in screenFrame: CGRect
    ) -> LayoutPreset.Region {
        let candidateRegions: [LayoutPreset.Region] = [
            .leftHalf, .rightHalf, .fullscreen,
            LayoutPreset.Region(x: 0, y: 0, width: 1.0 / 3.0, height: 1.0),     // left third
            LayoutPreset.Region(x: 1.0 / 3.0, y: 0, width: 1.0 / 3.0, height: 1.0), // center third
            LayoutPreset.Region(x: 2.0 / 3.0, y: 0, width: 1.0 / 3.0, height: 1.0), // right third
        ]

        var bestRegion = LayoutPreset.Region.rightHalf
        var leastOverlap = Double.greatestFiniteMagnitude

        for region in candidateRegions {
            let absoluteRect = resolveRegion(region, in: screenFrame)
            let totalOverlap = occupiedFrames.reduce(0.0) { total, occupied in
                let intersection = absoluteRect.intersection(occupied)
                return total + (intersection.isNull ? 0.0 : intersection.width * intersection.height)
            }

            if totalOverlap < leastOverlap {
                leastOverlap = totalOverlap
                bestRegion = region
            }
        }

        return bestRegion
    }

    /// Returns the complementary region (if target goes right, frontmost is on left).
    private func complementRegion(of region: LayoutPreset.Region) -> LayoutPreset.Region {
        if region == .rightHalf { return .leftHalf }
        if region == .leftHalf { return .rightHalf }
        return .fullscreen
    }
}
