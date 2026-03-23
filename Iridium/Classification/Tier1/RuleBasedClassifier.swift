//
//  RuleBasedClassifier.swift
//  Iridium
//

import Foundation
import OSLog

struct RuleBasedClassifier: ContentClassifier {
    private let utiClassifier = UTIClassifier()
    private let patternMatcher = PatternMatcher()

    func classify(uti: String?, sample: String?) async -> ClassificationResult {
        // Try UTI classification first (fastest path)
        if let uti, let contentType = utiClassifier.classify(uti: uti) {
            // For code UTIs, try to detect language from sample
            if contentType == .code, let sample {
                let language = patternMatcher.detectCodeLanguage(sample)
                return ClassificationResult(
                    contentType: .code,
                    language: language ?? .unknown,
                    confidence: 0.90,
                    tier: .ruleBased
                )
            }

            // Safety net: if UTI says prose but content looks like code,
            // trust the content. IDEs may put rich-text UTIs on the pasteboard.
            if contentType == .prose, let sample,
               let patternResult = patternMatcher.match(sample: sample),
               patternResult.contentType == .code
            {
                return ClassificationResult(
                    contentType: .code,
                    language: patternResult.language,
                    confidence: patternResult.confidence,
                    tier: .ruleBased
                )
            }

            return ClassificationResult(
                contentType: contentType,
                language: nil,
                confidence: 0.90,
                tier: .ruleBased
            )
        }

        // UTI was ambiguous (e.g., plain-text, html, rtf) — try pattern matching on content
        if let sample {
            if let result = patternMatcher.match(sample: sample) {
                return ClassificationResult(
                    contentType: result.contentType,
                    language: result.language,
                    confidence: result.confidence,
                    tier: .ruleBased
                )
            }
        }

        Logger.classification.debug("Tier 1: no confident classification")
        return .unknown
    }
}
