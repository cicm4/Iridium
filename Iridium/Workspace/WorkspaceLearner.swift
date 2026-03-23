//
//  WorkspaceLearner.swift
//  Iridium
//
//  Observes app co-activation patterns over time and suggests workspace creation.
//  Uses a co-occurrence matrix with a sliding 30-minute window.
//

import AppKit
import Foundation
import OSLog

@MainActor
final class WorkspaceLearner {
    /// Minimum co-activations before suggesting a workspace.
    static let suggestionThreshold = 20

    /// Sliding window for co-activation detection (30 minutes).
    static let windowDuration: TimeInterval = 30 * 60

    /// Minimum apps in a co-occurrence group to suggest a workspace.
    static let minimumGroupSize = 2

    /// Co-occurrence matrix: bundleID → bundleID → count.
    private(set) var coOccurrences: [String: [String: Int]] = [:]

    /// Timestamps of recent app activations for sliding window.
    private var recentActivations: [(bundleID: String, timestamp: Date)] = []

    /// Records that a set of apps are currently co-active.
    func recordCoActivation(runningApps: Set<String>) {
        let now = Date()

        // Only track regular apps (not system processes)
        let apps = Array(runningApps)
        guard apps.count >= Self.minimumGroupSize else { return }

        // Prune old activations outside the window
        recentActivations.removeAll { now.timeIntervalSince($0.timestamp) > Self.windowDuration }

        // Record each pair
        for i in 0..<apps.count {
            for j in (i + 1)..<apps.count {
                let a = apps[i]
                let b = apps[j]
                incrementCoOccurrence(a, b)
            }
        }
    }

    /// Returns groups of apps that frequently co-occur, above the threshold.
    func suggestedGroups() -> [[String]] {
        // Find all pairs above threshold
        var strongPairs: [(String, String)] = []
        for (a, neighbors) in coOccurrences {
            for (b, count) in neighbors {
                if count >= Self.suggestionThreshold && a < b {  // Avoid duplicates
                    strongPairs.append((a, b))
                }
            }
        }

        guard !strongPairs.isEmpty else { return [] }

        // Cluster strong pairs into groups using union-find
        var groups: [[String]] = []
        var assigned: Set<String> = []

        for (a, b) in strongPairs {
            // Find existing group containing a or b
            if let groupIdx = groups.firstIndex(where: { $0.contains(a) || $0.contains(b) }) {
                if !groups[groupIdx].contains(a) { groups[groupIdx].append(a) }
                if !groups[groupIdx].contains(b) { groups[groupIdx].append(b) }
                assigned.insert(a)
                assigned.insert(b)
            } else {
                groups.append([a, b])
                assigned.insert(a)
                assigned.insert(b)
            }
        }

        return groups.filter { $0.count >= Self.minimumGroupSize }
    }

    /// Resets all learned data.
    func reset() {
        coOccurrences.removeAll()
        recentActivations.removeAll()
    }

    // MARK: - Private

    private func incrementCoOccurrence(_ a: String, _ b: String) {
        // Store both directions for easy lookup
        if coOccurrences[a] == nil { coOccurrences[a] = [:] }
        if coOccurrences[b] == nil { coOccurrences[b] = [:] }
        coOccurrences[a]?[b, default: 0] += 1
        coOccurrences[b]?[a, default: 0] += 1
    }
}
