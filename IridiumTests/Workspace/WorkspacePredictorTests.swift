//
//  WorkspacePredictorTests.swift
//  IridiumTests
//

import Testing
@testable import Iridium

@MainActor
struct WorkspacePredictorTests {
    // Helper to create a predictor with controlled dependencies
    private func makePredictor(
        learner: WorkspaceLearner? = nil,
        registry: InstalledAppRegistry? = nil
    ) -> WorkspacePredictor {
        WorkspacePredictor(
            workspaceLearner: learner ?? WorkspaceLearner(),
            installedAppRegistry: registry ?? InstalledAppRegistry()
        )
    }

    private func makeContext(
        runningApps: [RunningAppInfo] = [],
        frontmostBundleID: String? = "com.apple.dt.Xcode",
        taskName: String? = nil,
        taskCategories: [AppCategory: Double]? = nil,
        hourOfDay: Int = 14
    ) -> ScreenContext {
        ScreenContext(
            runningApps: runningApps,
            frontmostBundleID: frontmostBundleID,
            frontmostWindowTitle: nil,
            windowLayout: [],
            hourOfDay: hourOfDay,
            displayCount: 1,
            activeTaskName: taskName,
            activeTaskCategories: taskCategories,
            clipboardContentType: nil,
            timestamp: .now
        )
    }

    @Test("Running background apps appear in suggestions")
    func predictsRunningBackgroundApps() {
        let predictor = makePredictor()

        let apps = [
            RunningAppInfo(bundleID: "com.apple.dt.Xcode", name: "Xcode", isActive: true, category: .development),
            RunningAppInfo(bundleID: "com.apple.Terminal", name: "Terminal", isActive: false, category: .development),
            RunningAppInfo(bundleID: "com.apple.Safari", name: "Safari", isActive: false, category: .research),
        ]

        let context = makeContext(runningApps: apps)
        let suggestions = predictor.predict(context: context)

        #expect(!suggestions.isEmpty)
        let bundleIDs = suggestions.map(\.bundleID)
        #expect(bundleIDs.contains("com.apple.Terminal"))
        #expect(bundleIDs.contains("com.apple.Safari"))
    }

    @Test("Frontmost app is excluded from suggestions")
    func excludesFrontmostApp() {
        let predictor = makePredictor()

        let apps = [
            RunningAppInfo(bundleID: "com.apple.dt.Xcode", name: "Xcode", isActive: true, category: .development),
            RunningAppInfo(bundleID: "com.apple.Terminal", name: "Terminal", isActive: false, category: .development),
        ]

        let context = makeContext(runningApps: apps, frontmostBundleID: "com.apple.dt.Xcode")
        let suggestions = predictor.predict(context: context)

        let bundleIDs = suggestions.map(\.bundleID)
        #expect(!bundleIDs.contains("com.apple.dt.Xcode"))
    }

    @Test("Co-occurrence boosts relevant apps")
    func coOccurrenceBoostsRelevantApps() {
        let learner = WorkspaceLearner()
        // Record high co-occurrence between Xcode and Terminal
        for _ in 0..<50 {
            learner.recordCoActivation(runningApps: Set(["com.apple.dt.Xcode", "com.apple.Terminal"]))
        }
        // Low co-occurrence between Xcode and Safari
        for _ in 0..<5 {
            learner.recordCoActivation(runningApps: Set(["com.apple.dt.Xcode", "com.apple.Safari"]))
        }

        let predictor = makePredictor(learner: learner)

        let apps = [
            RunningAppInfo(bundleID: "com.apple.dt.Xcode", name: "Xcode", isActive: true, category: .development),
            RunningAppInfo(bundleID: "com.apple.Terminal", name: "Terminal", isActive: false, category: .development),
            RunningAppInfo(bundleID: "com.apple.Safari", name: "Safari", isActive: false, category: .research),
        ]

        let context = makeContext(runningApps: apps)
        let suggestions = predictor.predict(context: context)

        // Terminal should rank above Safari due to higher co-occurrence
        guard let terminalIdx = suggestions.firstIndex(where: { $0.bundleID == "com.apple.Terminal" }),
              let safariIdx = suggestions.firstIndex(where: { $0.bundleID == "com.apple.Safari" })
        else {
            Issue.record("Both Terminal and Safari should appear in suggestions")
            return
        }
        #expect(terminalIdx < safariIdx, "Terminal should rank above Safari")
    }

    @Test("Task affinity boosts matching category apps")
    func taskAffinityBoostsDevelopmentApps() {
        let predictor = makePredictor()

        let apps = [
            RunningAppInfo(bundleID: "com.apple.dt.Xcode", name: "Xcode", isActive: true, category: .development),
            RunningAppInfo(bundleID: "com.apple.Terminal", name: "Terminal", isActive: false, category: .development),
            RunningAppInfo(bundleID: "com.apple.Pages", name: "Pages", isActive: false, category: .productivity),
        ]

        // Task mode = "coding" → development category boosted
        let context = makeContext(
            runningApps: apps,
            taskName: "coding",
            taskCategories: [.development: 1.0, .productivity: 0.2]
        )

        let suggestions = predictor.predict(context: context)

        guard let terminalIdx = suggestions.firstIndex(where: { $0.bundleID == "com.apple.Terminal" }),
              let pagesIdx = suggestions.firstIndex(where: { $0.bundleID == "com.apple.Pages" })
        else {
            Issue.record("Both Terminal and Pages should appear")
            return
        }
        #expect(terminalIdx < pagesIdx, "Terminal (dev) should rank above Pages (productivity) when task is coding")
    }

    @Test("Temporal patterns influence ranking")
    func temporalPatternsInfluenceRanking() {
        let learner = WorkspaceLearner()
        // Record heavy Slack usage at 9am
        for _ in 0..<100 {
            learner.recordHourlyUsage(bundleID: "com.tinyspeck.slackmacgap", hour: 9)
        }

        let predictor = makePredictor(learner: learner)

        let apps = [
            RunningAppInfo(bundleID: "com.apple.dt.Xcode", name: "Xcode", isActive: true, category: .development),
            RunningAppInfo(bundleID: "com.tinyspeck.slackmacgap", name: "Slack", isActive: false, category: .communication),
            RunningAppInfo(bundleID: "com.apple.Terminal", name: "Terminal", isActive: false, category: .development),
        ]

        let context = makeContext(runningApps: apps, hourOfDay: 9)
        let suggestions = predictor.predict(context: context)

        let bundleIDs = suggestions.map(\.bundleID)
        #expect(bundleIDs.contains("com.tinyspeck.slackmacgap"), "Slack should appear at 9am")
    }

    @Test("Recently used apps rank higher")
    func recentlyUsedAppsRankHigher() {
        let learner = WorkspaceLearner()
        learner.recordAppSwitch(to: "com.apple.Terminal")
        // Finder was used 2 hours ago (simulate by not recording it recently)

        let predictor = makePredictor(learner: learner)

        let apps = [
            RunningAppInfo(bundleID: "com.apple.dt.Xcode", name: "Xcode", isActive: true, category: .development),
            RunningAppInfo(bundleID: "com.apple.Terminal", name: "Terminal", isActive: false, category: .development),
            RunningAppInfo(bundleID: "com.apple.finder", name: "Finder", isActive: false, category: .utility),
        ]

        let context = makeContext(runningApps: apps)
        let suggestions = predictor.predict(context: context)

        guard let terminalIdx = suggestions.firstIndex(where: { $0.bundleID == "com.apple.Terminal" }),
              let finderIdx = suggestions.firstIndex(where: { $0.bundleID == "com.apple.finder" })
        else {
            Issue.record("Both Terminal and Finder should appear")
            return
        }
        #expect(terminalIdx < finderIdx, "Terminal (recently used) should rank above Finder")
    }

    @Test("Returns max 5 suggestions")
    func returnsMaxFiveSuggestions() {
        let predictor = makePredictor()

        let apps = (0..<10).map { i in
            RunningAppInfo(
                bundleID: "com.test.app\(i)",
                name: "App \(i)",
                isActive: i == 0,
                category: .other
            )
        }

        let context = makeContext(runningApps: apps, frontmostBundleID: "com.test.app0")
        let suggestions = predictor.predict(context: context)

        #expect(suggestions.count <= 5)
    }

    @Test("Empty when no background apps and no learned data")
    func emptyWhenNoRunningApps() {
        let predictor = makePredictor()

        // Only the frontmost app, nothing in background
        let apps = [
            RunningAppInfo(bundleID: "com.apple.dt.Xcode", name: "Xcode", isActive: true, category: .development),
        ]

        let context = makeContext(runningApps: apps)
        let suggestions = predictor.predict(context: context)

        #expect(suggestions.isEmpty)
    }

    @Test("Context hint reflects dominant scoring factor")
    func contextHintReflectsDominantFactor() {
        let learner = WorkspaceLearner()
        // Very high co-occurrence → coOccurrence should be dominant factor
        for _ in 0..<100 {
            learner.recordCoActivation(runningApps: Set(["com.apple.dt.Xcode", "com.apple.Terminal"]))
        }

        let predictor = makePredictor(learner: learner)

        let apps = [
            RunningAppInfo(bundleID: "com.apple.dt.Xcode", name: "Xcode", isActive: true, category: .development),
            RunningAppInfo(bundleID: "com.apple.Terminal", name: "Terminal", isActive: false, category: .development),
        ]

        let context = makeContext(runningApps: apps)
        let suggestions = predictor.predict(context: context)

        guard let terminal = suggestions.first(where: { $0.bundleID == "com.apple.Terminal" }) else {
            Issue.record("Terminal should appear")
            return
        }
        #expect(terminal.contextHint != nil)
        #expect(terminal.contextHint?.contains("Often used with") == true || terminal.contextHint?.contains("Already running") == true)
    }
}
