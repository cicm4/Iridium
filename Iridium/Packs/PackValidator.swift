//
//  PackValidator.swift
//  Iridium
//

import Foundation
import OSLog

struct PackValidationError: Error, CustomStringConvertible {
    let message: String
    var description: String { message }
}

struct PackValidator: Sendable {
    private static let knownSignals: Set<String> = [
        "clipboard.contentType",
        "clipboard.language",
        "app.frontmost",
        "time.hourOfDay",
        "display.count",
    ]

    func validate(_ manifest: PackManifest) throws {
        // Validate ID is reverse-DNS style
        guard manifest.id.contains("."), manifest.id.count >= 3 else {
            throw PackValidationError(message: "Pack ID '\(manifest.id)' must be reverse-DNS format (e.g., com.example.pack)")
        }

        // Validate name
        guard !manifest.name.isEmpty else {
            throw PackValidationError(message: "Pack name cannot be empty")
        }

        // Validate version (basic semver check)
        let versionParts = manifest.version.split(separator: ".")
        guard versionParts.count >= 2, versionParts.allSatisfy({ Int($0) != nil }) else {
            throw PackValidationError(message: "Version '\(manifest.version)' must be semver format (e.g., 1.0.0)")
        }

        // Validate triggers
        guard !manifest.triggers.isEmpty else {
            throw PackValidationError(message: "Pack must have at least one trigger")
        }

        for (index, trigger) in manifest.triggers.enumerated() {
            try validateTrigger(trigger, index: index)
        }

        Logger.packs.debug("Pack '\(manifest.id)' validated successfully")
    }

    private func validateTrigger(_ trigger: PackManifest.Trigger, index: Int) throws {
        // Validate confidence range
        guard (0.0...1.0).contains(trigger.confidence) else {
            throw PackValidationError(message: "Trigger[\(index)]: confidence must be 0.0-1.0, got \(trigger.confidence)")
        }

        // Validate suggestions
        guard !trigger.suggest.isEmpty else {
            throw PackValidationError(message: "Trigger[\(index)]: suggest array must not be empty")
        }

        // Validate signal names
        if let signal = trigger.signal {
            guard Self.knownSignals.contains(signal) else {
                throw PackValidationError(message: "Trigger[\(index)]: unknown signal '\(signal)'")
            }
        }

        if let conditions = trigger.conditions {
            for (ci, condition) in conditions.enumerated() {
                guard Self.knownSignals.contains(condition.signal) else {
                    throw PackValidationError(message: "Trigger[\(index)].conditions[\(ci)]: unknown signal '\(condition.signal)'")
                }
            }
        }

        // Must have either signal+matches or conditions
        if trigger.signal == nil && trigger.conditions == nil {
            throw PackValidationError(message: "Trigger[\(index)]: must have either 'signal'+'matches' or 'conditions'")
        }
    }
}
