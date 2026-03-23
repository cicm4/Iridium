//
//  IntegrationsSettingsView.swift
//  Iridium
//
//  Settings view for managing third-party integrations.
//

import SwiftUI

struct IntegrationsSettingsView: View {
    @Environment(IntegrationRegistry.self) private var registry
    @State private var tokenInputs: [String: String] = [:]

    var body: some View {
        Form {
            Section("Third-Party Integrations") {
                Text("Integrations connect to external services to provide richer context for suggestions.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(registry.integrations, id: \.id) { integration in
                    integrationRow(integration)
                }
            }

            Section("Privacy") {
                Text("API tokens are stored securely in your macOS Keychain. Integration data stays on your device — only API calls to the specific service are made.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private func integrationRow(_ integration: any IridiumIntegration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: integration.iconSystemName)
                    .foregroundStyle(.tint)
                    .frame(width: 20)
                VStack(alignment: .leading) {
                    Text(integration.name)
                        .font(.body)
                    Text(integration.integrationDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { registry.enabledIDs.contains(integration.id) },
                    set: { enabled in
                        Task {
                            if enabled {
                                await registry.enable(id: integration.id)
                            } else {
                                await registry.disable(id: integration.id)
                            }
                        }
                    }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
            }

            if integration.requiresToken {
                HStack {
                    SecureField(
                        "API Token",
                        text: Binding(
                            get: { tokenInputs[integration.id] ?? "" },
                            set: { tokenInputs[integration.id] = $0 }
                        )
                    )
                    .textFieldStyle(.roundedBorder)
                    .controlSize(.small)

                    Button("Save") {
                        if let token = tokenInputs[integration.id], !token.isEmpty {
                            registry.setToken(token, for: integration.id)
                            tokenInputs[integration.id] = ""
                        }
                    }
                    .controlSize(.small)

                    if registry.hasToken(for: integration.id) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                }
            }

            // Show required permissions
            if !integration.requiredPermissions.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "lock.shield")
                        .font(.caption2)
                    Text(permissionSummary(integration.requiredPermissions))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func permissionSummary(_ permissions: [IntegrationPermission]) -> String {
        permissions.map { perm in
            switch perm {
            case .network(let host): return "Network: \(host)"
            case .fileRead(let scope): return "Read: \(scope)"
            case .notification: return "Notifications"
            }
        }.joined(separator: ", ")
    }
}
