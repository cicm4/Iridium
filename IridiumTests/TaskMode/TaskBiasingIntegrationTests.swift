//
//  TaskBiasingIntegrationTests.swift
//  IridiumTests
//
//  Integration tests verifying task mode biases suggestion ranking.
//

import Foundation
import Testing
@testable import Iridium

@Suite("Task Mode Biasing Integration")
struct TaskBiasingIntegrationTests {

    @Test("Video task boosts creative/media apps over dev apps")
    func videoTaskBoostsCreativeApps() {
        let ranker = SuggestionRanker()
        let tracker = InteractionTracker()
        let registry = InstalledAppRegistry()

        // Simulate known apps (use bundleID-based category fallback)
        let task = TaskContext(
            name: "video editing",
            resolvedCategories: [.media: 0.9, .creativity: 0.8]
        )

        let suggestions = [
            // Dev app (should not be boosted)
            Suggestion(bundleID: "com.apple.dt.Xcode", confidence: 0.85, sourcePackID: "dev"),
            // Creative app (should be boosted by task)
            Suggestion(bundleID: "com.figma.Desktop", confidence: 0.85, sourcePackID: "creative"),
        ]

        // Without task: equal confidence → order depends on pack
        let withoutTask = ranker.rank(
            suggestions: suggestions,
            signalTimestamp: .now,
            interactionTracker: tracker
        )

        // With task: Figma should rank higher due to creativity boost
        let withTask = ranker.rank(
            suggestions: suggestions,
            signalTimestamp: .now,
            interactionTracker: tracker,
            taskContext: task,
            installedAppRegistry: registry
        )

        // Find Figma's rank in both
        let figmaWithout = withoutTask.firstIndex(where: { $0.bundleID == "com.figma.Desktop" })
        let figmaWith = withTask.firstIndex(where: { $0.bundleID == "com.figma.Desktop" })

        #expect(figmaWith != nil)
        #expect(figmaWith == 0, "With video task, Figma should rank first. Got: \(withTask.map(\.bundleID))")

        // Figma's confidence should be higher with task
        let figmaScoreWithTask = withTask.first(where: { $0.bundleID == "com.figma.Desktop" })?.confidence ?? 0
        let figmaScoreWithout = withoutTask.first(where: { $0.bundleID == "com.figma.Desktop" })?.confidence ?? 0
        #expect(figmaScoreWithTask > figmaScoreWithout,
                "Figma score with task (\(figmaScoreWithTask)) should exceed without (\(figmaScoreWithout))")
    }

    @Test("Coding task boosts dev apps over creative apps")
    func codingTaskBoostsDevApps() {
        let ranker = SuggestionRanker()
        let tracker = InteractionTracker()
        let registry = InstalledAppRegistry()

        let task = TaskContext(
            name: "coding",
            resolvedCategories: [.development: 1.0, .research: 0.3]
        )

        let suggestions = [
            Suggestion(bundleID: "com.figma.Desktop", confidence: 0.85, sourcePackID: "creative"),
            Suggestion(bundleID: "com.apple.dt.Xcode", confidence: 0.85, sourcePackID: "dev"),
        ]

        let ranked = ranker.rank(
            suggestions: suggestions,
            signalTimestamp: .now,
            interactionTracker: tracker,
            taskContext: task,
            installedAppRegistry: registry
        )

        #expect(ranked[0].bundleID == "com.apple.dt.Xcode",
                "With coding task, Xcode should rank first. Got: \(ranked.map(\.bundleID))")
    }

    @Test("No task means no bias (scores unchanged)")
    func noTaskNoBias() {
        let ranker = SuggestionRanker()
        let tracker = InteractionTracker()
        let registry = InstalledAppRegistry()

        let suggestions = [
            Suggestion(bundleID: "com.app.a", confidence: 0.90, sourcePackID: "test"),
            Suggestion(bundleID: "com.app.b", confidence: 0.85, sourcePackID: "test"),
        ]

        let withRegistry = ranker.rank(
            suggestions: suggestions,
            signalTimestamp: .now,
            interactionTracker: tracker,
            taskContext: nil,
            installedAppRegistry: registry
        )

        let without = ranker.rank(
            suggestions: suggestions,
            signalTimestamp: .now,
            interactionTracker: tracker
        )

        // Same order, same relative scores
        #expect(withRegistry[0].bundleID == without[0].bundleID)
        #expect(withRegistry[1].bundleID == without[1].bundleID)
    }

    @Test("Task deactivation removes bias")
    func taskDeactivationRemovesBias() async {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("IridiumTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = TaskStore(directory: dir)
        await store.startTask(description: "video editing")
        #expect(store.activeTask != nil)

        store.stopTask()
        #expect(store.activeTask == nil, "After stopping, activeTask should be nil")

        // Ranking with nil task should produce no bias
        let ranker = SuggestionRanker()
        let tracker = InteractionTracker()
        let suggestions = [
            Suggestion(bundleID: "com.apple.dt.Xcode", confidence: 0.85, sourcePackID: "dev"),
            Suggestion(bundleID: "com.figma.Desktop", confidence: 0.85, sourcePackID: "creative"),
        ]

        let ranked = ranker.rank(
            suggestions: suggestions,
            signalTimestamp: .now,
            interactionTracker: tracker,
            taskContext: store.activeTask,
            installedAppRegistry: InstalledAppRegistry()
        )

        // Without bias, order is by insertion (both equal confidence)
        #expect(ranked.count == 2)
    }

    @Test("Full resolver + ranker pipeline: 'video editing' biases creative apps")
    func fullResolverPipeline() async {
        let resolver = KeywordTaskResolver()
        let categories = await resolver.resolve(description: "video editing project")

        let task = TaskContext(name: "video editing project", resolvedCategories: categories)

        // Verify resolver produced media/creativity categories
        #expect(task.resolvedCategories[.media] != nil, "Resolver should produce media category")
        #expect(task.resolvedCategories[.creativity] != nil, "Resolver should produce creativity category")

        // Verify multiplier
        let mediaMultiplier = task.multiplier(for: .media)
        #expect(mediaMultiplier > 1.0, "Media apps should get boosted: \(mediaMultiplier)")

        let devMultiplier = task.multiplier(for: .development)
        #expect(devMultiplier == 1.0, "Dev apps should not be boosted for video task")
    }
}
