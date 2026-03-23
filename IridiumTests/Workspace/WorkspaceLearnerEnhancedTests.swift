//
//  WorkspaceLearnerEnhancedTests.swift
//  IridiumTests
//

import Foundation
import Testing
@testable import Iridium

@MainActor
struct WorkspaceLearnerEnhancedTests {
    @Test("Records hourly usage correctly")
    func recordsHourlyUsage() {
        let learner = WorkspaceLearner()

        learner.recordHourlyUsage(bundleID: "com.apple.Terminal", hour: 14)
        learner.recordHourlyUsage(bundleID: "com.apple.Terminal", hour: 14)
        learner.recordHourlyUsage(bundleID: "com.apple.Terminal", hour: 9)

        let freq14 = learner.hourlyFrequency(bundleID: "com.apple.Terminal", hour: 14)
        let freq9 = learner.hourlyFrequency(bundleID: "com.apple.Terminal", hour: 9)
        let freq0 = learner.hourlyFrequency(bundleID: "com.apple.Terminal", hour: 0)

        #expect(freq14 > freq9, "Hour 14 with 2 records should have higher frequency than hour 9 with 1")
        #expect(freq0 == 0.0, "Hour 0 should have zero frequency")
    }

    @Test("Records app switch timestamps")
    func recordsAppSwitchTimestamp() {
        let learner = WorkspaceLearner()

        learner.recordAppSwitch(to: "com.apple.Terminal")

        let lastSwitch = learner.lastSwitchTime(bundleID: "com.apple.Terminal")
        #expect(lastSwitch != nil, "Should have a recorded switch time")

        let elapsed = Date().timeIntervalSince(lastSwitch!)
        #expect(elapsed < 2.0, "Switch time should be very recent")

        let noSwitch = learner.lastSwitchTime(bundleID: "com.apple.Safari")
        #expect(noSwitch == nil, "Safari should have no switch time")
    }

    @Test("Records and retrieves layout preferences")
    func recordsLayoutPreference() {
        let learner = WorkspaceLearner()

        learner.recordLayoutChoice(
            appA: "com.apple.dt.Xcode",
            regionA: .leftHalf,
            appB: "com.apple.Terminal",
            regionB: .rightHalf
        )

        let learned = learner.preferredLayout(forPair: "com.apple.dt.Xcode", "com.apple.Terminal")
        #expect(learned != nil)
        #expect(learned?.regionA == .leftHalf)
        #expect(learned?.regionB == .rightHalf)
        #expect(learned?.count == 1)

        // Also works in reverse order
        let reversed = learner.preferredLayout(forPair: "com.apple.Terminal", "com.apple.dt.Xcode")
        #expect(reversed != nil)
    }

    @Test("Layout preference count increments on repeat")
    func layoutPreferenceCountIncrements() {
        let learner = WorkspaceLearner()

        for _ in 0..<5 {
            learner.recordLayoutChoice(
                appA: "com.apple.dt.Xcode",
                regionA: .leftHalf,
                appB: "com.apple.Terminal",
                regionB: .rightHalf
            )
        }

        let learned = learner.preferredLayout(forPair: "com.apple.dt.Xcode", "com.apple.Terminal")
        #expect(learned?.count == 5)
    }

    @Test("Top co-occurrence pairs returns correct results")
    func topCoOccurrencePairs() {
        let learner = WorkspaceLearner()

        for _ in 0..<50 {
            learner.recordCoActivation(runningApps: Set(["com.apple.dt.Xcode", "com.apple.Terminal"]))
        }
        for _ in 0..<20 {
            learner.recordCoActivation(runningApps: Set(["com.apple.Safari", "com.apple.Notes"]))
        }

        let top = learner.topCoOccurrencePairs(limit: 5)
        #expect(!top.isEmpty)
        #expect(top[0].0 == "com.apple.dt.Xcode" || top[0].0 == "com.apple.Terminal")
        #expect(top[0].2 == 50, "First pair should have count 50")
    }

    @Test("Reset clears all enhanced data")
    func resetClearsAll() {
        let learner = WorkspaceLearner()

        learner.recordAppSwitch(to: "com.apple.Terminal")
        learner.recordHourlyUsage(bundleID: "com.apple.Terminal", hour: 14)
        learner.recordLayoutChoice(appA: "a", regionA: .leftHalf, appB: "b", regionB: .rightHalf)
        learner.recordCoActivation(runningApps: Set(["a", "b"]))

        learner.reset()

        #expect(learner.lastSwitchTime(bundleID: "com.apple.Terminal") == nil)
        #expect(learner.hourlyFrequency(bundleID: "com.apple.Terminal", hour: 14) == 0.0)
        #expect(learner.preferredLayout(forPair: "a", "b") == nil)
        #expect(learner.coOccurrences.isEmpty)
    }
}
