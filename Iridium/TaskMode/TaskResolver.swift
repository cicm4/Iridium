//
//  TaskResolver.swift
//  Iridium
//
//  Protocol for resolving a task description into category weights.
//

import Foundation

protocol TaskResolver: Sendable {
    /// Resolves a task description into category weights.
    /// Returns a dictionary mapping AppCategory to a weight in [0, 1].
    func resolve(description: String) async -> [AppCategory: Double]
}
