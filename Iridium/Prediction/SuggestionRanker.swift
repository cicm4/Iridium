//
//  SuggestionRanker.swift
//  Iridium
//

import Foundation
import OSLog

struct SuggestionRanker: Sendable {
    private let scorer = ConfidenceScorer()

    /// Ranks, deduplicates, and caps suggestions.
    func rank(
        suggestions: [Suggestion],
        signalTimestamp: ContinuousClock.Instant,
        interactionTracker: InteractionTracker
    ) -> [Suggestion] {
        let now = ContinuousClock.now
        let signalAge = now - signalTimestamp

        // Score each suggestion
        var scored: [(Suggestion, Double)] = suggestions.map { suggestion in
            let boost = interactionTracker.boostForBundleID(suggestion.bundleID)
            let score = scorer.score(
                suggestion: suggestion,
                signalAge: signalAge,
                interactionBoost: boost
            )
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
