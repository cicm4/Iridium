//
//  ConfidenceScorer.swift
//  Iridium
//

import Foundation

struct ConfidenceScorer: Sendable {
    /// Normalizes and adjusts confidence scores based on signal freshness and interaction history.
    func score(
        suggestion: Suggestion,
        signalAge: Duration,
        interactionBoost: Double
    ) -> Double {
        var score = suggestion.confidence

        // Apply interaction history boost
        score += interactionBoost

        // Apply freshness decay: suggestions become less relevant over time
        let ageSeconds = Double(signalAge.components.seconds)
        if ageSeconds > 2.0 {
            let decayFactor = max(0.5, 1.0 - (ageSeconds - 2.0) / 30.0)
            score *= decayFactor
        }

        return min(1.0, max(0.0, score))
    }
}
