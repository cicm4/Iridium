//
//  PackManifest.swift
//  Iridium
//

import Foundation

struct PackManifest: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let version: String
    let author: String?
    let description: String?
    let minimumIridiumVersion: String?
    let triggers: [Trigger]

    struct Trigger: Codable, Sendable {
        let signal: String?
        let matches: MatchExpression?
        let conditions: [Condition]?
        let confidence: Double
        let suggest: [String]
    }

    struct Condition: Codable, Sendable {
        let signal: String
        let matches: MatchExpression
    }
}

enum MatchExpression: Codable, Sendable, Equatable {
    case exact(String)
    case anyOf([String])
    case range(gte: Double?, lte: Double?)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try string first (most common case)
        if let stringValue = try? container.decode(String.self) {
            self = .exact(stringValue)
            return
        }

        // Try array of strings
        if let arrayValue = try? container.decode([String].self) {
            self = .anyOf(arrayValue)
            return
        }

        // Try range object
        let rangeContainer = try decoder.container(keyedBy: RangeKeys.self)
        let gte = try rangeContainer.decodeIfPresent(Double.self, forKey: .gte)
        let lte = try rangeContainer.decodeIfPresent(Double.self, forKey: .lte)
        if gte != nil || lte != nil {
            self = .range(gte: gte, lte: lte)
            return
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Cannot decode MatchExpression")
        )
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .exact(let value):
            var container = encoder.singleValueContainer()
            try container.encode(value)
        case .anyOf(let values):
            var container = encoder.singleValueContainer()
            try container.encode(values)
        case .range(let gte, let lte):
            var container = encoder.container(keyedBy: RangeKeys.self)
            try container.encodeIfPresent(gte, forKey: .gte)
            try container.encodeIfPresent(lte, forKey: .lte)
        }
    }

    private enum RangeKeys: String, CodingKey {
        case gte, lte
    }
}
