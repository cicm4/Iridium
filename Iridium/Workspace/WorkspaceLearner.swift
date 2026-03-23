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

    /// Hourly usage frequency: bundleID → hour (0-23) → count.
    private(set) var hourlyUsage: [String: [Int: Int]] = [:]

    /// App switch recency: bundleID → last switch timestamp.
    private(set) var lastSwitchTimestamps: [String: Date] = [:]

    /// Layout preferences: "bundleA|bundleB" → learned region pair.
    private(set) var layoutPreferences: [String: LearnedLayoutPair] = [:]

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

    // MARK: - Enhanced Tracking (Phase 4)

    /// Records an app switch for recency tracking.
    func recordAppSwitch(to bundleID: String) {
        lastSwitchTimestamps[bundleID] = Date()
    }

    /// Records hourly usage for temporal pattern tracking.
    func recordHourlyUsage(bundleID: String, hour: Int) {
        if hourlyUsage[bundleID] == nil { hourlyUsage[bundleID] = [:] }
        hourlyUsage[bundleID]?[hour, default: 0] += 1
    }

    /// Records a layout choice for a pair of apps.
    func recordLayoutChoice(
        appA: String, regionA: LayoutPreset.Region,
        appB: String, regionB: LayoutPreset.Region
    ) {
        let key = layoutKey(appA, appB)
        let isReversed = appA > appB

        if var existing = layoutPreferences[key] {
            existing.count += 1
            // Update regions if this is the same orientation
            if !isReversed {
                existing.regionA = regionA
                existing.regionB = regionB
            } else {
                existing.regionA = regionB
                existing.regionB = regionA
            }
            layoutPreferences[key] = existing
        } else {
            layoutPreferences[key] = LearnedLayoutPair(
                regionA: isReversed ? regionB : regionA,
                regionB: isReversed ? regionA : regionB,
                count: 1
            )
        }
    }

    /// Returns the preferred layout for a pair of apps, if one has been learned.
    func preferredLayout(forPair appA: String, _ appB: String) -> LearnedLayoutPair? {
        let key = layoutKey(appA, appB)
        guard var pair = layoutPreferences[key] else { return nil }

        // If queried in reverse order, swap regions
        if appA > appB {
            let temp = pair.regionA
            pair.regionA = pair.regionB
            pair.regionB = temp
        }
        return pair
    }

    /// Returns the normalized hourly frequency for an app at a given hour (0.0 to 1.0).
    func hourlyFrequency(bundleID: String, hour: Int) -> Double {
        guard let hours = hourlyUsage[bundleID],
              let count = hours[hour], count > 0 else { return 0.0 }

        let maxCount = hours.values.max() ?? 1
        return Double(count) / Double(max(maxCount, 1))
    }

    /// Returns the last time the user switched to this app.
    func lastSwitchTime(bundleID: String) -> Date? {
        lastSwitchTimestamps[bundleID]
    }

    /// Returns the top N co-occurrence pairs sorted by count.
    func topCoOccurrencePairs(limit: Int) -> [(String, String, Int)] {
        var pairs: [(String, String, Int)] = []
        for (a, neighbors) in coOccurrences {
            for (b, count) in neighbors where a < b {
                pairs.append((a, b, count))
            }
        }
        return pairs.sorted { $0.2 > $1.2 }.prefix(limit).map { $0 }
    }

    /// Resets all learned data.
    func reset() {
        coOccurrences.removeAll()
        recentActivations.removeAll()
        hourlyUsage.removeAll()
        lastSwitchTimestamps.removeAll()
        layoutPreferences.removeAll()
    }

    // MARK: - Private

    private func incrementCoOccurrence(_ a: String, _ b: String) {
        // Store both directions for easy lookup
        if coOccurrences[a] == nil { coOccurrences[a] = [:] }
        if coOccurrences[b] == nil { coOccurrences[b] = [:] }
        coOccurrences[a]?[b, default: 0] += 1
        coOccurrences[b]?[a, default: 0] += 1
    }

    private func layoutKey(_ a: String, _ b: String) -> String {
        // Canonical key: sorted alphabetically
        a < b ? "\(a)|\(b)" : "\(b)|\(a)"
    }
}

// MARK: - Learned Layout Pair

struct LearnedLayoutPair: Codable, Sendable, Equatable {
    var regionA: LayoutPreset.Region
    var regionB: LayoutPreset.Region
    var count: Int
}
