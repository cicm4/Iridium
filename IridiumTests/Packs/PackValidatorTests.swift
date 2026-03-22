//
//  PackValidatorTests.swift
//  IridiumTests
//

import Testing
@testable import Iridium

struct PackValidatorTests {
    let validator = PackValidator()

    private func validManifest(
        id: String = "com.test.pack",
        name: String = "Test",
        version: String = "1.0.0",
        triggers: [PackManifest.Trigger]? = nil
    ) -> PackManifest {
        PackManifest(
            id: id,
            name: name,
            version: version,
            author: nil,
            description: nil,
            minimumIridiumVersion: nil,
            triggers: triggers ?? [
                PackManifest.Trigger(
                    signal: "clipboard.contentType",
                    matches: .exact("code"),
                    conditions: nil,
                    confidence: 0.9,
                    suggest: ["com.apple.dt.Xcode"]
                )
            ]
        )
    }

    // MARK: - Valid Packs

    @Test func validPackPasses() throws {
        try validator.validate(validManifest())
    }

    // MARK: - ID Validation

    @Test func rejectsIDWithoutDot() {
        #expect(throws: PackValidationError.self) {
            try validator.validate(validManifest(id: "noDots"))
        }
    }

    @Test func rejectsTooShortID() {
        #expect(throws: PackValidationError.self) {
            try validator.validate(validManifest(id: "a."))
        }
    }

    // MARK: - Name Validation

    @Test func rejectsEmptyName() {
        #expect(throws: PackValidationError.self) {
            try validator.validate(validManifest(name: ""))
        }
    }

    // MARK: - Version Validation

    @Test func rejectsInvalidVersion() {
        #expect(throws: PackValidationError.self) {
            try validator.validate(validManifest(version: "not-a-version"))
        }
    }

    @Test func acceptsTwoPartVersion() throws {
        try validator.validate(validManifest(version: "1.0"))
    }

    @Test func acceptsThreePartVersion() throws {
        try validator.validate(validManifest(version: "1.2.3"))
    }

    // MARK: - Trigger Validation

    @Test func rejectsEmptyTriggers() {
        #expect(throws: PackValidationError.self) {
            try validator.validate(validManifest(triggers: []))
        }
    }

    @Test func rejectsConfidenceAboveOne() {
        let trigger = PackManifest.Trigger(
            signal: "clipboard.contentType", matches: .exact("code"),
            conditions: nil, confidence: 1.5, suggest: ["com.app"]
        )
        #expect(throws: PackValidationError.self) {
            try validator.validate(validManifest(triggers: [trigger]))
        }
    }

    @Test func rejectsNegativeConfidence() {
        let trigger = PackManifest.Trigger(
            signal: "clipboard.contentType", matches: .exact("code"),
            conditions: nil, confidence: -0.1, suggest: ["com.app"]
        )
        #expect(throws: PackValidationError.self) {
            try validator.validate(validManifest(triggers: [trigger]))
        }
    }

    @Test func rejectsEmptySuggest() {
        let trigger = PackManifest.Trigger(
            signal: "clipboard.contentType", matches: .exact("code"),
            conditions: nil, confidence: 0.9, suggest: []
        )
        #expect(throws: PackValidationError.self) {
            try validator.validate(validManifest(triggers: [trigger]))
        }
    }

    @Test func rejectsUnknownSignal() {
        let trigger = PackManifest.Trigger(
            signal: "clipboard.unknownSignal", matches: .exact("code"),
            conditions: nil, confidence: 0.9, suggest: ["com.app"]
        )
        #expect(throws: PackValidationError.self) {
            try validator.validate(validManifest(triggers: [trigger]))
        }
    }

    @Test func rejectsTriggerWithNoSignalOrConditions() {
        let trigger = PackManifest.Trigger(
            signal: nil, matches: nil,
            conditions: nil, confidence: 0.9, suggest: ["com.app"]
        )
        #expect(throws: PackValidationError.self) {
            try validator.validate(validManifest(triggers: [trigger]))
        }
    }
}
