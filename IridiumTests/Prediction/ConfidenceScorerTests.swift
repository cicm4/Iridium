//
//  ConfidenceScorerTests.swift
//  IridiumTests
//

import Testing
@testable import Iridium

struct ConfidenceScorerTests {
    let scorer = ConfidenceScorer()

    private func suggestion(confidence: Double = 0.9) -> Suggestion {
        Suggestion(bundleID: "com.test", confidence: confidence, sourcePackID: "com.test.pack")
    }

    // MARK: - Fresh Signals (no decay)

    @Test func freshSignalNoDecay() {
        let score = scorer.score(
            suggestion: suggestion(confidence: 0.9),
            signalAge: .seconds(0),
            interactionBoost: 0
        )
        #expect(score == 0.9)
    }

    @Test func signalUnder2SecondsNoDecay() {
        let score = scorer.score(
            suggestion: suggestion(confidence: 0.9),
            signalAge: .seconds(1),
            interactionBoost: 0
        )
        #expect(score == 0.9)
    }

    // MARK: - Decay After 2 Seconds

    @Test func decayAfter2Seconds() {
        let score = scorer.score(
            suggestion: suggestion(confidence: 0.9),
            signalAge: .seconds(10),
            interactionBoost: 0
        )
        // After 10s: decayFactor = max(0.5, 1.0 - (10-2)/30) = max(0.5, 0.733) = 0.733
        // score = 0.9 * 0.733 = ~0.66
        #expect(score < 0.9)
        #expect(score > 0.5)
    }

    @Test func decayFloorAt50Percent() {
        let score = scorer.score(
            suggestion: suggestion(confidence: 0.9),
            signalAge: .seconds(60),
            interactionBoost: 0
        )
        // After 60s: decayFactor floors at 0.5
        // score = 0.9 * 0.5 = 0.45
        #expect(score == 0.9 * 0.5)
    }

    // MARK: - Interaction Boost

    @Test func interactionBoostAddsToScore() {
        let score = scorer.score(
            suggestion: suggestion(confidence: 0.8),
            signalAge: .seconds(0),
            interactionBoost: 0.1
        )
        #expect(score == 0.9)
    }

    @Test func boostCapsAtOne() {
        let score = scorer.score(
            suggestion: suggestion(confidence: 0.95),
            signalAge: .seconds(0),
            interactionBoost: 0.15
        )
        #expect(score == 1.0)
    }

    // MARK: - Score Bounds

    @Test func scoreNeverNegative() {
        let score = scorer.score(
            suggestion: suggestion(confidence: 0.0),
            signalAge: .seconds(100),
            interactionBoost: 0
        )
        #expect(score >= 0.0)
    }

    @Test func scoreNeverAboveOne() {
        let score = scorer.score(
            suggestion: suggestion(confidence: 1.0),
            signalAge: .seconds(0),
            interactionBoost: 0.15
        )
        #expect(score <= 1.0)
    }
}
