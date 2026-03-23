//
//  BetaDistribution.swift
//  Iridium
//
//  Bayesian conjugate prior for tracking selection probability.
//  Beta(α, β) where α = successes + 1, β = failures + 1.
//  Mean = α / (α + β). Uniform prior starts at Beta(1, 1) = 0.5.
//

import Foundation

struct BetaDistribution: Codable, Sendable, Equatable {
    /// Successes + 1 (prior). Minimum 1.0 (uniform prior).
    var alpha: Double

    /// Failures + 1 (prior). Minimum 1.0 (uniform prior).
    var beta: Double

    /// Timestamp of the last update, used for time-based decay.
    var lastUpdated: Date

    /// Uniform prior: Beta(1, 1) with mean 0.5.
    static let uniformPrior = BetaDistribution(alpha: 1.0, beta: 1.0, lastUpdated: Date())

    /// Expected value: α / (α + β).
    var mean: Double {
        alpha / (alpha + beta)
    }

    /// Total observations (α + β - 2, since prior starts at 1,1).
    var totalObservations: Double {
        (alpha - 1) + (beta - 1)
    }

    /// Records a selection (success) or appearance-without-selection (failure).
    mutating func update(selected: Bool) {
        if selected {
            alpha += 1
        } else {
            beta += 1
        }
        lastUpdated = Date()
    }

    /// Returns a new distribution with counts decayed by a factor.
    /// Factor 0.5 = half-life reached. Preserves minimum prior of Beta(1,1).
    func decayed(by factor: Double) -> BetaDistribution {
        let clampedFactor = max(0, min(1, factor))
        // Decay the observation counts, not the prior
        let decayedAlpha = 1.0 + (alpha - 1.0) * clampedFactor
        let decayedBeta = 1.0 + (beta - 1.0) * clampedFactor
        return BetaDistribution(
            alpha: max(1.0, decayedAlpha),
            beta: max(1.0, decayedBeta),
            lastUpdated: lastUpdated
        )
    }

    /// Decay factor for a given time interval using exponential decay.
    /// Half-life in seconds. Returns factor in [0, 1].
    static func decayFactor(elapsed: TimeInterval, halfLife: TimeInterval) -> Double {
        guard halfLife > 0, elapsed >= 0 else { return 1.0 }
        return pow(0.5, elapsed / halfLife)
    }
}
