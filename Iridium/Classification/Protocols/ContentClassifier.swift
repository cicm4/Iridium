//
//  ContentClassifier.swift
//  Iridium
//

import Foundation

struct ClassificationResult: Sendable {
    let contentType: ContentType
    let language: ProgrammingLanguage?
    let confidence: Double
    let tier: ClassificationTier

    static let unknown = ClassificationResult(
        contentType: .unknown,
        language: nil,
        confidence: 0.0,
        tier: .ruleBased
    )
}

enum ClassificationTier: Int, Sendable, Comparable {
    case ruleBased = 1
    case nlFramework = 2
    case foundationModel = 3

    static func < (lhs: ClassificationTier, rhs: ClassificationTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

protocol ContentClassifier: Sendable {
    func classify(uti: String?, sample: String?) async -> ClassificationResult
}
