//
//  BetaDistributionTests.swift
//  IridiumTests
//

import Foundation
import Testing
@testable import Iridium

@Suite("BetaDistribution")
struct BetaDistributionTests {

    @Test("Uniform prior has mean 0.5")
    func uniformPriorMean() {
        let dist = BetaDistribution.uniformPrior
        #expect(dist.alpha == 1.0)
        #expect(dist.beta == 1.0)
        #expect(dist.mean == 0.5)
    }

    @Test("Selection increases mean above 0.5")
    func selectionIncreasesMean() {
        var dist = BetaDistribution.uniformPrior
        dist.update(selected: true)
        #expect(dist.mean > 0.5, "Mean should increase after selection: \(dist.mean)")
        #expect(dist.alpha == 2.0)
        #expect(dist.beta == 1.0)
        // Expected: 2/3 ≈ 0.667
        #expect(abs(dist.mean - 2.0 / 3.0) < 0.001)
    }

    @Test("Non-selection decreases mean below 0.5")
    func nonSelectionDecreasesMean() {
        var dist = BetaDistribution.uniformPrior
        dist.update(selected: false)
        #expect(dist.mean < 0.5, "Mean should decrease after non-selection: \(dist.mean)")
        // Expected: 1/3 ≈ 0.333
        #expect(abs(dist.mean - 1.0 / 3.0) < 0.001)
    }

    @Test("Multiple selections converge toward 1.0")
    func multipleSelectionsConverge() {
        var dist = BetaDistribution.uniformPrior
        for _ in 0..<20 {
            dist.update(selected: true)
        }
        #expect(dist.mean > 0.9, "After 20 selections, mean should be near 1.0: \(dist.mean)")
    }

    @Test("Decay reduces observation counts proportionally")
    func decayReducesCounts() {
        var dist = BetaDistribution.uniformPrior
        for _ in 0..<10 {
            dist.update(selected: true)
        }

        let original = dist
        let decayed = dist.decayed(by: 0.5)

        // Alpha was 11 (1 + 10 selections). After 0.5 decay: 1 + 5 = 6
        #expect(decayed.alpha < original.alpha, "Decayed alpha should be less")
        #expect(decayed.beta == original.beta, "Beta unchanged (no non-selections)")
        #expect(abs(decayed.alpha - 6.0) < 0.001)
    }

    @Test("Decay preserves minimum prior of Beta(1,1)")
    func decayPreservesMinimum() {
        let dist = BetaDistribution.uniformPrior
        let decayed = dist.decayed(by: 0.0)  // Full decay
        #expect(decayed.alpha >= 1.0)
        #expect(decayed.beta >= 1.0)
        #expect(decayed.mean == 0.5, "Fully decayed should return to uniform")
    }

    @Test("Decay factor computation")
    func decayFactorComputation() {
        // At half-life, factor should be 0.5
        let factor = BetaDistribution.decayFactor(elapsed: 7 * 24 * 3600, halfLife: 7 * 24 * 3600)
        #expect(abs(factor - 0.5) < 0.001)

        // At zero elapsed, factor should be 1.0
        let noDecay = BetaDistribution.decayFactor(elapsed: 0, halfLife: 7 * 24 * 3600)
        #expect(abs(noDecay - 1.0) < 0.001)

        // At double half-life, factor should be 0.25
        let doubleDecay = BetaDistribution.decayFactor(elapsed: 14 * 24 * 3600, halfLife: 7 * 24 * 3600)
        #expect(abs(doubleDecay - 0.25) < 0.001)
    }

    @Test("totalObservations counts correctly")
    func totalObservations() {
        var dist = BetaDistribution.uniformPrior
        #expect(dist.totalObservations == 0, "Fresh distribution has 0 observations")

        dist.update(selected: true)
        dist.update(selected: false)
        #expect(dist.totalObservations == 2)
    }

    @Test("Codable round-trip preserves values")
    func codableRoundTrip() throws {
        var dist = BetaDistribution.uniformPrior
        dist.update(selected: true)
        dist.update(selected: true)
        dist.update(selected: false)

        let encoder = JSONEncoder()
        let data = try encoder.encode(dist)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(BetaDistribution.self, from: data)

        #expect(decoded.alpha == dist.alpha)
        #expect(decoded.beta == dist.beta)
        #expect(decoded.mean == dist.mean)
    }
}
