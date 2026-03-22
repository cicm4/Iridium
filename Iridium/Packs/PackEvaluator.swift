//
//  PackEvaluator.swift
//  Iridium
//

import Foundation
import OSLog

struct PackEvaluator: Sendable {
    private let triggerMatcher = TriggerMatcher()

    func evaluate(signal: ContextSignal, packs: [PackManifest]) -> [Suggestion] {
        var suggestions: [Suggestion] = []

        for pack in packs {
            for trigger in pack.triggers {
                guard triggerMatcher.matches(trigger, signal: signal) else { continue }

                for bundleID in trigger.suggest {
                    suggestions.append(Suggestion(
                        bundleID: bundleID,
                        confidence: trigger.confidence,
                        sourcePackID: pack.id
                    ))
                }
            }
        }

        Logger.packs.debug("Evaluated \(packs.count) packs, produced \(suggestions.count) suggestions")
        return suggestions
    }
}
