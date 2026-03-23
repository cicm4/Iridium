//
//  AdaptiveWeightStore.swift
//  Iridium
//
//  Persistent Bayesian weight store that learns from user selections.
//  Each (ContentType, BundleID) pair has a Beta distribution tracking
//  selection probability. Weights decay over time (7-day half-life).
//

import Foundation
import OSLog

@Observable
final class AdaptiveWeightStore: @unchecked Sendable {
    /// Half-life for exponential decay: 7 days in seconds.
    static let decayHalfLife: TimeInterval = 7 * 24 * 3600

    /// Maximum adaptive boost applied to suggestion scores.
    static let maxBoost: Double = 0.20

    /// Weight data: contentType → bundleID → distribution.
    private(set) var weights: [ContentType: [String: BetaDistribution]] = [:]

    /// Persistence manager (nil = in-memory only).
    private let persistence: LearningDataPersistence?

    /// Whether persistence is enabled.
    let isPersistent: Bool

    init(persistence: LearningDataPersistence? = nil) {
        self.persistence = persistence
        self.isPersistent = persistence != nil
    }

    /// Load previously saved weights from disk.
    func load() {
        guard let persistence else { return }
        if let loaded = persistence.load() {
            weights = loaded
            Logger.learning.info("Loaded adaptive weights: \(loaded.values.reduce(0) { $0 + $1.count }) entries")
        }
    }

    /// Save current weights to disk (debounced).
    func save() {
        guard let persistence else { return }
        persistence.save(weights)
    }

    /// Records that a suggestion was shown to the user but not selected.
    /// Call this when the panel is dismissed (not when it's shown — only on dismissal).
    func recordAppearance(bundleID: String, contentType: ContentType) {
        ensureEntry(bundleID: bundleID, contentType: contentType)
        weights[contentType]?[bundleID]?.update(selected: false)
        save()
    }

    /// Records that the user selected a suggestion.
    /// This is the positive signal — the user chose this app.
    func recordSelection(bundleID: String, contentType: ContentType) {
        ensureEntry(bundleID: bundleID, contentType: contentType)
        weights[contentType]?[bundleID]?.update(selected: true)
        save()
    }

    /// Returns the adaptive weight for a bundle ID given a content type.
    /// Applies time-based decay. Range: [0, maxBoost].
    ///
    /// The weight is based on the selection ratio (selections / total interactions).
    /// Apps that are selected more often than the baseline (50%) get a positive boost.
    /// Apps that are shown but never selected get zero boost.
    func weight(for bundleID: String, contentType: ContentType) -> Double {
        guard let dist = weights[contentType]?[bundleID] else {
            return 0.0  // No data = no boost
        }

        // Apply decay based on time since last update
        let elapsed = Date().timeIntervalSince(dist.lastUpdated)
        let factor = BetaDistribution.decayFactor(elapsed: elapsed, halfLife: Self.decayHalfLife)
        let decayed = dist.decayed(by: factor)

        // Only boost if we have enough observations (at least 2)
        guard decayed.totalObservations >= 2 else { return 0.0 }

        // Use the raw mean as the boost signal.
        // Mean > 0.5 means the app is selected more often than not → gets a boost.
        // Mean < 0.5 means it's ignored → gets no boost.
        // Mean == 0.5 (equal selections and dismissals) → small boost (better than unknown).
        //
        // We use a gentler formula: any app with data gets some boost proportional to its mean,
        // but apps with mean > 0.5 get disproportionately more.
        let mean = decayed.mean
        let boost = mean * mean * Self.maxBoost  // Quadratic: favors high-mean apps
        return min(boost, Self.maxBoost)
    }

    /// Returns all bundle IDs that have any weight data for a content type.
    func knownBundleIDs(for contentType: ContentType) -> Set<String> {
        guard let entries = weights[contentType] else { return [] }
        return Set(entries.keys)
    }

    /// Resets all learned weights.
    func reset() {
        weights.removeAll()
        save()
        Logger.learning.info("Adaptive weights reset")
    }

    // MARK: - Private

    private func ensureEntry(bundleID: String, contentType: ContentType) {
        if weights[contentType] == nil {
            weights[contentType] = [:]
        }
        if weights[contentType]?[bundleID] == nil {
            weights[contentType]?[bundleID] = .uniformPrior
        }
    }
}
