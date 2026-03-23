//
//  TaskContext.swift
//  Iridium
//
//  A user-defined task that biases suggestion weights toward relevant app categories.
//  e.g., "editing a video" → boost creativity + media apps.
//

import Foundation

struct TaskContext: Codable, Sendable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var resolvedCategories: [AppCategory: Double]
    var createdAt: Date
    var isActive: Bool

    /// Maximum multiplicative factor applied to suggestion scores.
    /// 1.5× means a perfectly matching app gets 50% more confidence.
    static let maxMultiplier: Double = 1.5

    init(
        id: UUID = UUID(),
        name: String,
        resolvedCategories: [AppCategory: Double] = [:],
        createdAt: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.resolvedCategories = resolvedCategories
        self.createdAt = createdAt
        self.isActive = isActive
    }

    /// Returns the multiplicative boost for a given app category.
    /// Range: [1.0, maxMultiplier]. Categories not in the task return 1.0 (no boost).
    func multiplier(for category: AppCategory) -> Double {
        guard let weight = resolvedCategories[category], weight > 0 else {
            return 1.0
        }
        // Scale weight (0..1) to multiplier range (1.0..maxMultiplier)
        return 1.0 + weight * (Self.maxMultiplier - 1.0)
    }
}
