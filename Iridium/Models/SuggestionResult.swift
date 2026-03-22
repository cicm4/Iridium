//
//  SuggestionResult.swift
//  Iridium
//

import Foundation

struct SuggestionResult: Sendable {
    let suggestions: [Suggestion]
    let signal: ContextSignal

    static let empty = SuggestionResult(suggestions: [], signal: ContextSignal())

    /// Maximum number of suggestions to display.
    static let maxSuggestions = 5
}
