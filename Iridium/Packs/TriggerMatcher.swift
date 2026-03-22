//
//  TriggerMatcher.swift
//  Iridium
//

import Foundation

struct TriggerMatcher: Sendable {
    func matches(_ trigger: PackManifest.Trigger, signal: ContextSignal) -> Bool {
        // Single-condition shorthand
        if let signalName = trigger.signal, let matchExpr = trigger.matches {
            return matchesSingleCondition(signal: signalName, expression: matchExpr, context: signal)
        }

        // Multi-condition (all must match)
        if let conditions = trigger.conditions {
            return conditions.allSatisfy { condition in
                matchesSingleCondition(signal: condition.signal, expression: condition.matches, context: signal)
            }
        }

        return false
    }

    private func matchesSingleCondition(
        signal: String,
        expression: MatchExpression,
        context: ContextSignal
    ) -> Bool {
        guard let signalValue = resolveSignalValue(signal, from: context) else {
            return false
        }

        switch signalValue {
        case .string(let value):
            return matchesString(expression: expression, value: value)
        case .number(let value):
            return matchesNumber(expression: expression, value: value)
        }
    }

    private enum SignalValue {
        case string(String)
        case number(Double)
    }

    private func resolveSignalValue(_ signal: String, from context: ContextSignal) -> SignalValue? {
        switch signal {
        case "clipboard.contentType":
            return context.contentType.map { .string($0.rawValue) }
        case "clipboard.language":
            return context.language.map { .string($0.rawValue) }
        case "app.frontmost":
            return context.frontmostAppBundleID.map { .string($0) }
        case "time.hourOfDay":
            return .number(Double(context.hourOfDay))
        case "display.count":
            return .number(Double(context.displayCount))
        default:
            return nil
        }
    }

    private func matchesString(expression: MatchExpression, value: String) -> Bool {
        switch expression {
        case .exact(let expected):
            return value == expected
        case .anyOf(let options):
            return options.contains(value)
        case .range:
            return false
        }
    }

    private func matchesNumber(expression: MatchExpression, value: Double) -> Bool {
        switch expression {
        case .exact(let expected):
            return Double(expected) == value
        case .anyOf(let options):
            return options.compactMap(Double.init).contains(value)
        case .range(let gte, let lte):
            if let gte, value < gte { return false }
            if let lte, value > lte { return false }
            return true
        }
    }
}
