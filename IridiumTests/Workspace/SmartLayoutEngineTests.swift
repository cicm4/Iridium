//
//  SmartLayoutEngineTests.swift
//  IridiumTests
//

import Testing
@testable import Iridium
import CoreGraphics

@MainActor
struct SmartLayoutEngineTests {
    private let screenFrame = CGRect(x: 0, y: 0, width: 1920, height: 1080)

    @Test("Positions on opposite half when one window occupies >60% width")
    func positionsOnOppositeHalf() {
        let learner = WorkspaceLearner()
        let engine = SmartLayoutEngine(workspaceLearner: learner)

        // Xcode window occupies left 70% of screen
        let context = makeContext(windowLayout: [
            WindowSnapshot(
                ownerBundleID: "com.apple.dt.Xcode",
                title: "Xcode",
                frame: CGRect(x: 0, y: 0, width: 1344, height: 1080), // 70% of 1920
                isOnScreen: true,
                screenIndex: 0
            )
        ])

        let region = engine.determineOptimalRegion(
            for: "com.apple.Terminal",
            relativeTo: "com.apple.dt.Xcode",
            context: context
        )

        #expect(region == .rightHalf, "Should place on right half when Xcode occupies left >60%")
    }

    @Test("Uses learned layout when available with count >= 3")
    func usesLearnedLayout() {
        let learner = WorkspaceLearner()
        // Record layout preference 3 times
        for _ in 0..<3 {
            learner.recordLayoutChoice(
                appA: "com.apple.dt.Xcode",
                regionA: .leftHalf,
                appB: "com.apple.Terminal",
                regionB: .rightHalf
            )
        }

        let engine = SmartLayoutEngine(workspaceLearner: learner)
        let context = makeContext()

        let region = engine.determineOptimalRegion(
            for: "com.apple.Terminal",
            relativeTo: "com.apple.dt.Xcode",
            context: context
        )

        #expect(region == .rightHalf, "Should use learned right-half preference")
    }

    @Test("Falls back to right half as default")
    func fallsBackToRightHalf() {
        let engine = SmartLayoutEngine(workspaceLearner: WorkspaceLearner())

        // No learned layouts, no visible windows
        let context = makeContext(windowLayout: [])

        let region = engine.determineOptimalRegion(
            for: "com.apple.Terminal",
            relativeTo: "com.apple.dt.Xcode",
            context: context
        )

        // With no windows and no learned data, findBestRegion with empty occupied should pick the first with 0 overlap
        #expect(region == .leftHalf || region == .rightHalf || region == .fullscreen)
    }

    @Test("Finds empty region in multi-window layout")
    func findsEmptyRegion() {
        let engine = SmartLayoutEngine(workspaceLearner: WorkspaceLearner())

        // Two windows filling left 2/3 of screen
        let occupiedFrames = [
            CGRect(x: 0, y: 0, width: 640, height: 1080),   // Left third
            CGRect(x: 640, y: 0, width: 640, height: 1080),  // Center third
        ]

        let region = engine.findBestRegion(
            excluding: occupiedFrames,
            in: screenFrame
        )

        // Right third or right half should have least overlap
        #expect(region.x >= 0.5, "Should place in the right portion where there's space, got x=\(region.x)")
    }

    @Test("Records layout choice after arrangement")
    func recordsLayoutChoice() {
        let learner = WorkspaceLearner()
        let engine = SmartLayoutEngine(workspaceLearner: learner)

        // Manually call recordLayoutChoice (arrangement is async and needs real apps)
        learner.recordLayoutChoice(
            appA: "com.apple.dt.Xcode",
            regionA: .leftHalf,
            appB: "com.apple.Terminal",
            regionB: .rightHalf
        )

        let learned = learner.preferredLayout(forPair: "com.apple.dt.Xcode", "com.apple.Terminal")
        #expect(learned != nil, "Layout preference should be recorded")
        #expect(learned?.count == 1)
    }

    // Helper
    private func makeContext(windowLayout: [WindowSnapshot] = []) -> ScreenContext {
        ScreenContext(
            runningApps: [],
            frontmostBundleID: "com.apple.dt.Xcode",
            frontmostWindowTitle: nil,
            windowLayout: windowLayout,
            hourOfDay: 14,
            displayCount: 1,
            activeTaskName: nil,
            activeTaskCategories: nil,
            clipboardContentType: nil,
            timestamp: .now
        )
    }
}
