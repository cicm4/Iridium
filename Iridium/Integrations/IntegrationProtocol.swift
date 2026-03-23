//
//  IntegrationProtocol.swift
//  Iridium
//
//  Core protocol for third-party integrations.
//  Integrations contribute signals to the prediction engine in a sandboxed manner.
//

import Foundation

/// Permission types that integrations can request.
enum IntegrationPermission: Codable, Sendable, Equatable {
    case network(host: String)
    case fileRead(scope: String)
    case notification
}

/// Signal produced by an integration.
struct IntegrationSignal: Sendable, Equatable {
    /// Namespace (integration ID), e.g., "todoist"
    let namespace: String
    /// Signal key, e.g., "dueToday"
    let key: String
    /// Signal value as string (numbers are string-encoded for simplicity)
    let value: String

    /// Full signal name for TriggerMatcher: "namespace.key"
    var signalName: String { "\(namespace).\(key)" }
}

/// Limited context passed to integrations. Integrations cannot access main app state.
struct IntegrationContext: Sendable {
    /// Sandboxed data directory for this integration.
    let dataDirectory: URL
    /// Integration ID.
    let integrationID: String
}

/// Protocol that all integrations must conform to.
protocol IridiumIntegration: AnyObject, Sendable {
    /// Unique identifier (e.g., "todoist", "obsidian").
    var id: String { get }
    /// Display name.
    var name: String { get }
    /// Description of what this integration does.
    var integrationDescription: String { get }
    /// System image name for the icon.
    var iconSystemName: String { get }
    /// Permissions this integration requires.
    var requiredPermissions: [IntegrationPermission] { get }
    /// Whether this integration requires an API token.
    var requiresToken: Bool { get }

    /// Configure the integration with its sandboxed context.
    func configure(context: IntegrationContext, token: String?) async throws
    /// Start polling/monitoring.
    func start() async
    /// Stop polling/monitoring.
    func stop() async
    /// Returns current signals. Called periodically by IntegrationRegistry.
    func currentSignals() async -> [IntegrationSignal]
}
