//
//  TaskContextTests.swift
//  IridiumTests
//

import Foundation
import Testing
@testable import Iridium

@Suite("TaskContext")
struct TaskContextTests {

    @Test("Multiplier for matching category returns boost")
    func multiplierForMatchingCategory() {
        let task = TaskContext(
            name: "video editing",
            resolvedCategories: [.media: 0.9, .creativity: 0.8]
        )

        let mediaMultiplier = task.multiplier(for: .media)
        #expect(mediaMultiplier > 1.0, "Media should get a boost: \(mediaMultiplier)")
        #expect(mediaMultiplier <= TaskContext.maxMultiplier)
        // 1.0 + 0.9 * 0.5 = 1.45
        #expect(abs(mediaMultiplier - 1.45) < 0.01)
    }

    @Test("Multiplier for non-matching category returns 1.0")
    func multiplierForNonMatchingCategory() {
        let task = TaskContext(
            name: "video editing",
            resolvedCategories: [.media: 0.9]
        )

        let devMultiplier = task.multiplier(for: .development)
        #expect(devMultiplier == 1.0, "Non-matching category should return 1.0: \(devMultiplier)")
    }

    @Test("Multiplier for empty categories returns 1.0")
    func multiplierForEmptyCategories() {
        let task = TaskContext(name: "unknown task", resolvedCategories: [:])
        #expect(task.multiplier(for: .development) == 1.0)
        #expect(task.multiplier(for: .media) == 1.0)
    }

    @Test("Codable round-trip preserves values")
    func codableRoundTrip() throws {
        let task = TaskContext(
            name: "test task",
            resolvedCategories: [.development: 1.0, .research: 0.3]
        )

        let data = try JSONEncoder().encode(task)
        let decoded = try JSONDecoder().decode(TaskContext.self, from: data)

        #expect(decoded.name == task.name)
        #expect(decoded.resolvedCategories == task.resolvedCategories)
        #expect(decoded.id == task.id)
        #expect(decoded.isActive == task.isActive)
    }

    @Test("Max multiplier is 1.5x")
    func maxMultiplier() {
        let task = TaskContext(
            name: "all-in",
            resolvedCategories: [.development: 1.0]
        )

        let multiplier = task.multiplier(for: .development)
        #expect(multiplier == TaskContext.maxMultiplier)
        #expect(multiplier == 1.5)
    }
}
