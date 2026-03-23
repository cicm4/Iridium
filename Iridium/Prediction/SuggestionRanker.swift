//
//  SuggestionRanker.swift
//  Iridium
//

import Foundation
import OSLog

struct SuggestionRanker: Sendable {
    private let scorer = ConfidenceScorer()

    /// Boost applied to suggestions whose app is currently running.
    /// Enough to move a running app ahead of a non-running one at equal confidence,
    /// but not so large that it overrides a significantly better match.
    static let runningAppBoost: Double = 0.10

    /// Boost applied to suggestions whose app is pinned by the user.
    static let pinnedAppBoost: Double = 0.25

    /// Maximum boost from adaptive learning based on user history.
    static let maxAdaptiveBoost: Double = 0.20

    /// Ranks, deduplicates, and caps suggestions.
    /// - Parameters:
    ///   - suggestions: Raw suggestions from pack evaluation.
    ///   - signalTimestamp: When the signal was created (for freshness decay).
    ///   - interactionTracker: Tracks user selections for interaction boost.
    ///   - runningAppBundleIDs: Bundle IDs of currently running apps. Running apps
    ///     receive a ranking boost so the most relevant, already-open apps surface first.
    ///   - excludedBundleIDs: Bundle IDs the user has explicitly excluded from suggestions.
    ///   - pinnedBundleIDs: Bundle IDs the user has pinned to appear first.
    ///   - adaptiveWeightStore: Persistent Bayesian weight store for learned preferences.
    ///   - contentType: Content type of the current signal (for adaptive weight lookup).
    func rank(
        suggestions: [Suggestion],
        signalTimestamp: ContinuousClock.Instant,
        interactionTracker: InteractionTracker,
        runningAppBundleIDs: Set<String> = [],
        excludedBundleIDs: Set<String> = [],
        pinnedBundleIDs: Set<String> = [],
        adaptiveWeightStore: AdaptiveWeightStore? = nil,
        contentType: ContentType? = nil
    ) -> [Suggestion] {
        let now = ContinuousClock.now
        let signalAge = now - signalTimestamp

        // Filter excluded apps FIRST
        let nonExcluded = suggestions.filter { !excludedBundleIDs.contains($0.bundleID) }

        // Score each suggestion
        var scored: [(Suggestion, Double)] = nonExcluded.map { suggestion in
            let interactionBoost = interactionTracker.boostForBundleID(suggestion.bundleID)
            var score = scorer.score(
                suggestion: suggestion,
                signalAge: signalAge,
                interactionBoost: interactionBoost
            )

            // Boost currently running apps
            if runningAppBundleIDs.contains(suggestion.bundleID) {
                score += Self.runningAppBoost
            }

            // Boost pinned apps
            if pinnedBundleIDs.contains(suggestion.bundleID) {
                score += Self.pinnedAppBoost
            }

            // Adaptive learning boost (persistent user preference)
            if let store = adaptiveWeightStore, let ct = contentType {
                score += store.weight(for: suggestion.bundleID, contentType: ct)
            }

            return (suggestion, score)
        }

        // Sort by score descending
        scored.sort { $0.1 > $1.1 }

        // Deduplicate by bundle ID (keep highest scoring)
        var seen = Set<String>()
        var deduped: [Suggestion] = []
        for (suggestion, score) in scored {
            guard !seen.contains(suggestion.bundleID) else { continue }
            seen.insert(suggestion.bundleID)
            deduped.append(Suggestion(
                bundleID: suggestion.bundleID,
                confidence: score,
                sourcePackID: suggestion.sourcePackID
            ))
        }

        // Cap at max suggestions
        let result = Array(deduped.prefix(SuggestionResult.maxSuggestions))
        Logger.prediction.debug("Ranked \(suggestions.count) → \(result.count) suggestions")
        return result
    }
}
