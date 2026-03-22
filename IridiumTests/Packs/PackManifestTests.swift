//
//  PackManifestTests.swift
//  IridiumTests
//

import Testing
import Foundation
@testable import Iridium

struct PackManifestTests {
    // MARK: - Valid JSON Parsing

    @Test func parsesValidPackJSON() throws {
        let json = """
        {
            "id": "com.test.pack",
            "name": "Test Pack",
            "version": "1.0.0",
            "triggers": [{
                "signal": "clipboard.contentType",
                "matches": "code",
                "confidence": 0.9,
                "suggest": ["com.apple.dt.Xcode"]
            }]
        }
        """
        let data = json.data(using: .utf8)!
        let manifest = try JSONDecoder().decode(PackManifest.self, from: data)
        #expect(manifest.id == "com.test.pack")
        #expect(manifest.name == "Test Pack")
        #expect(manifest.version == "1.0.0")
        #expect(manifest.triggers.count == 1)
        #expect(manifest.triggers[0].suggest == ["com.apple.dt.Xcode"])
    }

    @Test func parsesMultiConditionTrigger() throws {
        let json = """
        {
            "id": "com.test.multi",
            "name": "Multi",
            "version": "1.0.0",
            "triggers": [{
                "conditions": [
                    {"signal": "clipboard.contentType", "matches": "code"},
                    {"signal": "clipboard.language", "matches": "swift"}
                ],
                "confidence": 0.95,
                "suggest": ["com.apple.dt.Xcode"]
            }]
        }
        """
        let data = json.data(using: .utf8)!
        let manifest = try JSONDecoder().decode(PackManifest.self, from: data)
        #expect(manifest.triggers[0].conditions?.count == 2)
    }

    // MARK: - Match Expression Parsing

    @Test func parsesExactMatch() throws {
        let json = "\"code\""
        let data = json.data(using: .utf8)!
        let expr = try JSONDecoder().decode(MatchExpression.self, from: data)
        #expect(expr == .exact("code"))
    }

    @Test func parsesAnyOfMatch() throws {
        let json = "[\"swift\", \"python\"]"
        let data = json.data(using: .utf8)!
        let expr = try JSONDecoder().decode(MatchExpression.self, from: data)
        #expect(expr == .anyOf(["swift", "python"]))
    }

    @Test func parsesRangeMatch() throws {
        let json = "{\"gte\": 9, \"lte\": 17}"
        let data = json.data(using: .utf8)!
        let expr = try JSONDecoder().decode(MatchExpression.self, from: data)
        #expect(expr == .range(gte: 9, lte: 17))
    }

    @Test func parsesRangeWithOnlyGte() throws {
        let json = "{\"gte\": 18}"
        let data = json.data(using: .utf8)!
        let expr = try JSONDecoder().decode(MatchExpression.self, from: data)
        #expect(expr == .range(gte: 18, lte: nil))
    }

    // MARK: - Invalid JSON

    @Test func rejectsMissingRequiredFields() {
        let json = "{\"id\": \"test\"}"
        let data = json.data(using: .utf8)!
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(PackManifest.self, from: data)
        }
    }
}
