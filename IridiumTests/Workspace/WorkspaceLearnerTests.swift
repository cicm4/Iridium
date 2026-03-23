//
//  WorkspaceLearnerTests.swift
//  IridiumTests
//

import Testing
@testable import Iridium

@Suite("WorkspaceLearner")
struct WorkspaceLearnerTests {

    @Test("Co-occurrence counting")
    @MainActor
    func coOccurrenceCounting() {
        let learner = WorkspaceLearner()

        let apps: Set<String> = ["com.app.a", "com.app.b", "com.app.c"]
        learner.recordCoActivation(runningApps: apps)

        #expect(learner.coOccurrences["com.app.a"]?["com.app.b"] == 1)
        #expect(learner.coOccurrences["com.app.b"]?["com.app.a"] == 1)
        #expect(learner.coOccurrences["com.app.a"]?["com.app.c"] == 1)
    }

    @Test("Repeated co-activation increments count")
    @MainActor
    func repeatedCoActivation() {
        let learner = WorkspaceLearner()

        for _ in 0..<5 {
            learner.recordCoActivation(runningApps: ["com.app.a", "com.app.b"])
        }

        #expect(learner.coOccurrences["com.app.a"]?["com.app.b"] == 5)
    }

    @Test("Threshold triggers workspace suggestion")
    @MainActor
    func thresholdTriggers() {
        let learner = WorkspaceLearner()

        for _ in 0..<WorkspaceLearner.suggestionThreshold {
            learner.recordCoActivation(runningApps: ["com.app.a", "com.app.b"])
        }

        let groups = learner.suggestedGroups()
        #expect(!groups.isEmpty, "Should suggest a workspace after threshold")
        #expect(groups[0].contains("com.app.a"))
        #expect(groups[0].contains("com.app.b"))
    }

    @Test("Below threshold returns no suggestions")
    @MainActor
    func belowThreshold() {
        let learner = WorkspaceLearner()

        for _ in 0..<(WorkspaceLearner.suggestionThreshold - 1) {
            learner.recordCoActivation(runningApps: ["com.app.a", "com.app.b"])
        }

        let groups = learner.suggestedGroups()
        #expect(groups.isEmpty, "Should not suggest below threshold")
    }

    @Test("Single app does not trigger")
    @MainActor
    func singleAppNoTrigger() {
        let learner = WorkspaceLearner()
        learner.recordCoActivation(runningApps: ["com.app.a"])

        let groups = learner.suggestedGroups()
        #expect(groups.isEmpty)
    }

    @Test("Reset clears all data")
    @MainActor
    func resetClears() {
        let learner = WorkspaceLearner()

        for _ in 0..<25 {
            learner.recordCoActivation(runningApps: ["com.app.a", "com.app.b"])
        }

        learner.reset()
        #expect(learner.coOccurrences.isEmpty)
        #expect(learner.suggestedGroups().isEmpty)
    }
}
