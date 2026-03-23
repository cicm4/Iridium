//
//  IntegrationTests.swift
//  IridiumTests
//

import Foundation
import Testing
@testable import Iridium

// MARK: - Mock Integration

final class MockIntegration: IridiumIntegration, @unchecked Sendable {
    let id: String
    let name: String
    let integrationDescription = "Mock integration"
    let iconSystemName = "gear"
    let requiredPermissions: [IntegrationPermission] = []
    let requiresToken: Bool

    var isStarted = false
    var isStopped = false
    var configuredToken: String?
    var mockSignals: [IntegrationSignal] = []

    init(id: String, name: String, requiresToken: Bool = false) {
        self.id = id
        self.name = name
        self.requiresToken = requiresToken
    }

    func configure(context: IntegrationContext, token: String?) async throws {
        configuredToken = token
        if requiresToken && (token == nil || token!.isEmpty) {
            throw IntegrationError.missingToken
        }
    }

    func start() async { isStarted = true }
    func stop() async { isStopped = true }
    func currentSignals() async -> [IntegrationSignal] { mockSignals }
}

// MARK: - IntegrationSignal Tests

@Suite("IntegrationSignal")
struct IntegrationSignalTests {

    @Test("Signal name combines namespace and key")
    func signalName() {
        let signal = IntegrationSignal(namespace: "todoist", key: "dueToday", value: "5")
        #expect(signal.signalName == "todoist.dueToday")
    }

    @Test("Equality comparison")
    func equality() {
        let a = IntegrationSignal(namespace: "todoist", key: "dueToday", value: "5")
        let b = IntegrationSignal(namespace: "todoist", key: "dueToday", value: "5")
        #expect(a == b)
    }
}

// MARK: - IntegrationRegistry Tests

@Suite("IntegrationRegistry")
struct IntegrationRegistryTests {

    @Test("Register integration")
    @MainActor
    func registerIntegration() {
        let registry = IntegrationRegistry()
        let mock = MockIntegration(id: "test", name: "Test")
        registry.register(mock)

        #expect(registry.integrations.count == 1)
        #expect(registry.integrations[0].id == "test")
    }

    @Test("Duplicate registration is ignored")
    @MainActor
    func duplicateRegistration() {
        let registry = IntegrationRegistry()
        let mock1 = MockIntegration(id: "test", name: "Test 1")
        let mock2 = MockIntegration(id: "test", name: "Test 2")
        registry.register(mock1)
        registry.register(mock2)

        #expect(registry.integrations.count == 1)
    }

    @Test("Enable and disable integration")
    @MainActor
    func enableDisable() async {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("IridiumTests-\(UUID())")
        defer { try? FileManager.default.removeItem(at: dir) }

        let registry = IntegrationRegistry(baseDirectory: dir)
        let mock = MockIntegration(id: "test", name: "Test")
        registry.register(mock)

        await registry.enable(id: "test")
        #expect(registry.enabledIDs.contains("test"))
        #expect(mock.isStarted)

        await registry.disable(id: "test")
        #expect(!registry.enabledIDs.contains("test"))
        #expect(mock.isStopped)
    }

    @Test("Signal polling collects from enabled integrations")
    @MainActor
    func signalPolling() async {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("IridiumTests-\(UUID())")
        defer { try? FileManager.default.removeItem(at: dir) }

        let registry = IntegrationRegistry(baseDirectory: dir)
        let mock = MockIntegration(id: "test", name: "Test")
        mock.mockSignals = [
            IntegrationSignal(namespace: "test", key: "count", value: "42"),
            IntegrationSignal(namespace: "test", key: "status", value: "active"),
        ]
        registry.register(mock)
        registry.enabledIDs = ["test"]

        await registry.startAll()

        #expect(registry.currentSignals.count == 2)
        #expect(registry.signalDictionary["test.count"] == "42")
        #expect(registry.signalDictionary["test.status"] == "active")
    }

    @Test("Disabled integration signals are not collected")
    @MainActor
    func disabledNotCollected() async {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("IridiumTests-\(UUID())")
        defer { try? FileManager.default.removeItem(at: dir) }

        let registry = IntegrationRegistry(baseDirectory: dir)
        let mock = MockIntegration(id: "test", name: "Test")
        mock.mockSignals = [IntegrationSignal(namespace: "test", key: "x", value: "1")]
        registry.register(mock)
        // NOT enabled

        await registry.startAll()

        #expect(registry.currentSignals.isEmpty)
    }
}

// MARK: - TriggerMatcher Integration Signal Tests

@Suite("TriggerMatcher Integration Signals")
struct TriggerMatcherIntegrationSignalTests {

    @Test("TriggerMatcher resolves integration signal as string")
    func resolveIntegrationString() {
        let matcher = TriggerMatcher()
        let signal = ContextSignal(
            integrationSignals: ["todoist.currentProject": "Website Redesign"]
        )
        let trigger = PackManifest.Trigger(
            signal: "todoist.currentProject",
            matches: .exact("Website Redesign"),
            conditions: nil,
            confidence: 0.80,
            suggest: ["com.todoist.mac.Todoist"]
        )
        #expect(matcher.matches(trigger, signal: signal))
    }

    @Test("TriggerMatcher resolves integration signal as number")
    func resolveIntegrationNumber() {
        let matcher = TriggerMatcher()
        let signal = ContextSignal(
            integrationSignals: ["todoist.overdue": "3"]
        )
        let trigger = PackManifest.Trigger(
            signal: "todoist.overdue",
            matches: .range(gte: 1, lte: nil),
            conditions: nil,
            confidence: 0.85,
            suggest: ["com.todoist.mac.Todoist"]
        )
        #expect(matcher.matches(trigger, signal: signal))
    }

    @Test("TriggerMatcher returns false for missing integration signal")
    func missingIntegrationSignal() {
        let matcher = TriggerMatcher()
        let signal = ContextSignal()  // No integration signals
        let trigger = PackManifest.Trigger(
            signal: "todoist.overdue",
            matches: .range(gte: 1, lte: nil),
            conditions: nil,
            confidence: 0.85,
            suggest: ["com.todoist.mac.Todoist"]
        )
        #expect(!matcher.matches(trigger, signal: signal))
    }

    @Test("Full pipeline: integration signal triggers pack suggestion")
    func fullPipelineIntegrationSignal() {
        let evaluator = PackEvaluator()
        let loader = PackLoader()
        let allPacks = loader.loadBuiltInPacks()

        let todoistPack = allPacks.first { $0.id == "com.iridium.todoist-aware" }
        guard let pack = todoistPack else {
            #expect(Bool(false), "todoist-aware pack not found")
            return
        }

        let signal = ContextSignal(
            integrationSignals: ["todoist.overdue": "3"]
        )

        let suggestions = evaluator.evaluate(signal: signal, packs: [pack])
        #expect(!suggestions.isEmpty, "Overdue tasks should trigger todoist pack. Got: \(suggestions)")
    }
}

// MARK: - PackValidator Integration Signal Tests

@Suite("PackValidator Integration Signals")
struct PackValidatorIntegrationSignalTests {

    @Test("Validator accepts integration-namespaced signals")
    func acceptsIntegrationSignals() {
        let validator = PackValidator()
        let signals = ["todoist.dueToday", "todoist.overdue", "obsidian.recentTopic",
                       "obsidian.activeVault", "notion.recentPage", "notion.recentDatabase"]

        for signalName in signals {
            let manifest = PackManifest(
                id: "com.test.pack",
                name: "Test",
                version: "1.0",
                author: "Test",
                description: nil,
                minimumIridiumVersion: nil,
                triggers: [
                    PackManifest.Trigger(
                        signal: signalName,
                        matches: .exact("test"),
                        conditions: nil,
                        confidence: 0.80,
                        suggest: ["com.test.app"]
                    )
                ]
            )
            #expect(throws: Never.self) {
                try validator.validate(manifest)
            }
        }
    }

    @Test("Validator rejects unknown namespace")
    func rejectsUnknownNamespace() {
        let validator = PackValidator()
        let manifest = PackManifest(
            id: "com.test.pack",
            name: "Test",
            version: "1.0",
            author: "Test",
            description: nil,
            minimumIridiumVersion: nil,
            triggers: [
                PackManifest.Trigger(
                    signal: "unknown.signal",
                    matches: .exact("test"),
                    conditions: nil,
                    confidence: 0.80,
                    suggest: ["com.test.app"]
                )
            ]
        )
        #expect(throws: PackValidationError.self) {
            try validator.validate(manifest)
        }
    }
}

// MARK: - ContextSignal Integration Field Tests

@Suite("ContextSignal Integration Fields")
struct ContextSignalIntegrationFieldTests {

    @Test("Integration signals preserved through SignalFusion")
    func fusionPreservesIntegrationSignals() {
        let fusion = SignalFusion()
        let signal = ContextSignal(
            clipboardSample: "test",
            integrationSignals: ["todoist.dueToday": "5", "obsidian.activeVault": "MyVault"]
        )

        let classification = ClassificationResult(
            contentType: .prose,
            language: nil,
            confidence: 0.80,
            tier: .ruleBased
        )

        let enriched = fusion.enrich(signal: signal, classification: classification)

        #expect(enriched.integrationSignals?["todoist.dueToday"] == "5")
        #expect(enriched.integrationSignals?["obsidian.activeVault"] == "MyVault")
    }

    @Test("Integration signals default to nil")
    func defaultNil() {
        let signal = ContextSignal()
        #expect(signal.integrationSignals == nil)
    }
}
