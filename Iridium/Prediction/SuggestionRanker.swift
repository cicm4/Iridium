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

    /// Ranks, deduplicates, and caps suggestions.
    /// - Parameters:
    ///   - suggestions: Raw suggestions from pack evaluation.
    ///   - signalTimestamp: When the signal was created (for freshness decay).
    ///   - interactionTracker: Tracks user selections for interaction boost.
    ///   - runningAppBundleIDs: Bundle IDs of currently running apps. Running apps
    ///     receive a ranking boost so the most relevant, already-open apps surface first.
    func rank(
        suggestions: [Suggestion],
        signalTimestamp: ContinuousClock.Instant,
        interactionTracker: InteractionTracker,
        runningAppBundleIDs: Set<String> = []
    ) -> [Suggestion] {
        let now = ContinuousClock.now
        let signalAge = now - signalTimestamp

        // Score each suggestion
        var scored: [(Suggestion, Double)] = suggestions.map { suggestion in
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
