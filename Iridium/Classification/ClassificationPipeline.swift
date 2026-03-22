//
//  ClassificationPipeline.swift
//  Iridium
//

import Foundation
import OSLog

actor ClassificationPipeline {
    private let tier1: RuleBasedClassifier
    private let tier2: NLClassifier
    private let tier3: FoundationModelClassifier
    private let languageDetector: LanguageDetector

    private var enableFoundationModels: Bool

    init(enableFoundationModels: Bool = false) {
        self.tier1 = RuleBasedClassifier()
        self.tier2 = NLClassifier()
        self.tier3 = FoundationModelClassifier()
        self.languageDetector = LanguageDetector()
        self.enableFoundationModels = enableFoundationModels
    }

    func setFoundationModelsEnabled(_ enabled: Bool) {
        self.enableFoundationModels = enabled
    }

    /// Runs the tiered classification pipeline.
    /// Returns the Tier 1 result immediately and refines with Tier 2/3 if available.
    func classify(uti: String?, sample: String?) async -> ClassificationResult {
        // Tier 1: Rule-based (synchronous, < 50ms)
        let tier1Result = await tier1.classify(uti: uti, sample: sample)

        if tier1Result.confidence >= 0.90 {
            Logger.classification.debug("Tier 1 high confidence (\(tier1Result.confidence)): \(tier1Result.contentType.rawValue)")
            // Try to refine language detection even with high confidence
            if tier1Result.contentType == .code, tier1Result.language == .unknown,
               let sample
            {
                let detectedLang = languageDetector.detect(sample: sample)
                if let detectedLang {
                    return ClassificationResult(
                        contentType: .code,
                        language: detectedLang,
                        confidence: tier1Result.confidence,
                        tier: .ruleBased
                    )
                }
            }
            return tier1Result
        }

        // Tier 2: NL Framework (async, 50-200ms)
        let tier2Result = await withTimeout(duration: .milliseconds(200)) {
            await self.tier2.classify(uti: uti, sample: sample)
        }

        let bestResult: ClassificationResult
        if let tier2Result, tier2Result.confidence > tier1Result.confidence {
            Logger.classification.debug("Tier 2 improved: \(tier2Result.contentType.rawValue) (\(tier2Result.confidence) > \(tier1Result.confidence))")
            bestResult = tier2Result
        } else {
            bestResult = tier1Result
        }

        // Tier 3: Foundation Models (optional, 200-500ms)
        if enableFoundationModels, bestResult.confidence < 0.80 {
            let tier3Result = await withTimeout(duration: .milliseconds(500)) {
                await self.tier3.classify(uti: uti, sample: sample)
            }

            if let tier3Result, tier3Result.confidence > bestResult.confidence {
                Logger.classification.debug("Tier 3 improved: \(tier3Result.contentType.rawValue) (\(tier3Result.confidence))")
                return tier3Result
            }
        }

        return bestResult
    }

    /// Runs a quick classification using only Tier 1 for immediate display.
    func quickClassify(uti: String?, sample: String?) async -> ClassificationResult {
        await tier1.classify(uti: uti, sample: sample)
    }

    // MARK: - Helpers

    private func withTimeout<T: Sendable>(
        duration: Duration,
        operation: @escaping @Sendable () async -> T
    ) async -> T? {
        await withTaskGroup(of: T?.self) { group in
            group.addTask {
                await operation()
            }
            group.addTask {
                try? await Task.sleep(for: duration)
                return nil
            }

            // Return whichever finishes first
            if let result = await group.next() {
                group.cancelAll()
                return result
            }
            return nil
        }
    }
}
