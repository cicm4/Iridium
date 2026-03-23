//
//  IntegrationRegistry.swift
//  Iridium
//
//  Manages registered integrations, their lifecycle, and signal polling.
//

import Foundation
import Observation
import OSLog

@Observable
@MainActor
final class IntegrationRegistry {
    /// All registered integrations.
    private(set) var integrations: [any IridiumIntegration] = []

    /// Which integrations are enabled.
    var enabledIDs: Set<String> = []

    /// Most recent signals from all enabled integrations.
    private(set) var currentSignals: [IntegrationSignal] = []

    /// Polling interval for signal collection.
    static let pollInterval: TimeInterval = 60

    private let tokenStore: SecureTokenStore
    private var pollTimer: Timer?
    private let baseDataDirectory: URL

    init(
        tokenStore: SecureTokenStore = SecureTokenStore(),
        baseDirectory: URL? = nil
    ) {
        self.tokenStore = tokenStore
        self.baseDataDirectory = baseDirectory ?? FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
            .appendingPathComponent("Iridium")
            .appendingPathComponent("Integrations")
    }

    /// Registers an integration (does not start it).
    func register(_ integration: any IridiumIntegration) {
        guard !integrations.contains(where: { $0.id == integration.id }) else { return }
        integrations.append(integration)
        Logger.integrations.info("Registered integration: \(integration.id)")
    }

    /// Returns all enabled integrations.
    var enabledIntegrations: [any IridiumIntegration] {
        integrations.filter { enabledIDs.contains($0.id) }
    }

    /// Starts all enabled integrations.
    func startAll() async {
        for integration in enabledIntegrations {
            await startIntegration(integration)
        }

        // Start polling
        pollTimer = Timer.scheduledTimer(withTimeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.pollSignals()
            }
        }

        // Initial poll
        await pollSignals()

        Logger.integrations.info("Started \(self.enabledIntegrations.count) integrations")
    }

    /// Stops all integrations.
    func stopAll() async {
        pollTimer?.invalidate()
        pollTimer = nil

        for integration in integrations {
            await integration.stop()
        }

        currentSignals.removeAll()
        Logger.integrations.info("Stopped all integrations")
    }

    /// Enables an integration and starts it.
    func enable(id: String) async {
        enabledIDs.insert(id)
        if let integration = integrations.first(where: { $0.id == id }) {
            await startIntegration(integration)
        }
    }

    /// Disables an integration and stops it.
    func disable(id: String) async {
        enabledIDs.remove(id)
        if let integration = integrations.first(where: { $0.id == id }) {
            await integration.stop()
        }
        currentSignals.removeAll { $0.namespace == id }
    }

    /// Sets or updates the API token for an integration.
    func setToken(_ token: String, for integrationID: String) {
        _ = tokenStore.setToken(token, for: integrationID)
    }

    /// Checks if a token exists for an integration.
    func hasToken(for integrationID: String) -> Bool {
        tokenStore.hasToken(for: integrationID)
    }

    /// Returns the current signals as a dictionary for ContextSignal merging.
    var signalDictionary: [String: String] {
        var dict: [String: String] = [:]
        for signal in currentSignals {
            dict[signal.signalName] = signal.value
        }
        return dict
    }

    // MARK: - Private

    private func startIntegration(_ integration: any IridiumIntegration) async {
        let dataDir = baseDataDirectory.appendingPathComponent(integration.id)
        try? FileManager.default.createDirectory(at: dataDir, withIntermediateDirectories: true)

        let context = IntegrationContext(
            dataDirectory: dataDir,
            integrationID: integration.id
        )

        let token = integration.requiresToken ? tokenStore.token(for: integration.id) : nil

        do {
            try await integration.configure(context: context, token: token)
            await integration.start()
            Logger.integrations.info("Started integration: \(integration.id)")
        } catch {
            Logger.integrations.error("Failed to start \(integration.id): \(error.localizedDescription)")
        }
    }

    private func pollSignals() async {
        var allSignals: [IntegrationSignal] = []

        for integration in enabledIntegrations {
            let signals = await integration.currentSignals()
            allSignals.append(contentsOf: signals)
        }

        currentSignals = allSignals
        Logger.integrations.debug("Polled \(allSignals.count) signals from \(self.enabledIntegrations.count) integrations")
    }
}
