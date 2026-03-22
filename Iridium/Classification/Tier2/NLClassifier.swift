//
//  NLClassifier.swift
//  Iridium
//

import Foundation
import NaturalLanguage
import OSLog

struct NLClassifier: ContentClassifier {
    func classify(uti: String?, sample: String?) async -> ClassificationResult {
        guard let sample, !sample.isEmpty else { return .unknown }

        // Use NLLanguageRecognizer to detect human vs programming language patterns
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(sample)

        let dominantLanguage = recognizer.dominantLanguage

        // If NL framework recognizes it as a natural language with high confidence,
        // it's likely prose rather than code
        let hypotheses = recognizer.languageHypotheses(withMaximum: 3)
        let topConfidence = hypotheses.values.max() ?? 0

        // Use NLTagger for more detailed analysis
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = sample

        var wordCount = 0
        var symbolCount = 0

        tagger.enumerateTags(
            in: sample.startIndex..<sample.endIndex,
            unit: .word,
            scheme: .lexicalClass
        ) { tag, _ in
            if let tag {
                switch tag {
                case .noun, .verb, .adjective, .adverb, .pronoun, .determiner,
                     .preposition, .conjunction:
                    wordCount += 1
                case .punctuation, .otherPunctuation:
                    symbolCount += 1
                default:
                    break
                }
            }
            return true
        }

        // High natural language word ratio suggests prose
        let totalTokens = wordCount + symbolCount
        let wordRatio = totalTokens > 0 ? Double(wordCount) / Double(totalTokens) : 0

        if wordRatio > 0.7 && topConfidence > 0.8 {
            Logger.classification.debug("Tier 2: classified as prose (wordRatio=\(wordRatio), langConfidence=\(topConfidence))")
            return ClassificationResult(
                contentType: .prose,
                language: nil,
                confidence: min(0.85, topConfidence),
                tier: .nlFramework
            )
        }

        // Low natural language recognition might indicate code
        if topConfidence < 0.3 || dominantLanguage == nil {
            Logger.classification.debug("Tier 2: likely code (low NL confidence=\(topConfidence))")
            return ClassificationResult(
                contentType: .code,
                language: nil,
                confidence: 0.65,
                tier: .nlFramework
            )
        }

        Logger.classification.debug("Tier 2: inconclusive (wordRatio=\(wordRatio), confidence=\(topConfidence))")
        return .unknown
    }
}
