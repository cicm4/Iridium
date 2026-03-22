//
//  Suggestion.swift
//  Iridium
//

import Foundation

struct Suggestion: Sendable, Identifiable, Equatable {
    let id: String
    let bundleID: String
    let confidence: Double
    let sourcePackID: String

    init(bundleID: String, confidence: Double, sourcePackID: String) {
        self.id = "\(sourcePackID):\(bundleID)"
        self.bundleID = bundleID
        self.confidence = confidence
        self.sourcePackID = sourcePackID
    }
}
