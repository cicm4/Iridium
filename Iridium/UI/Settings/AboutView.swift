//
//  AboutView.swift
//  Iridium
//

import SwiftUI

struct AboutView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkle")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("Iridium")
                .font(.title)
                .fontWeight(.bold)

            Text("A privacy-first, predictive window manager for macOS")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                Text("Version \(version)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Label("No data leaves your device", systemImage: "lock.shield")
                Label("No telemetry or analytics", systemImage: "eye.slash")
                Label("All signals processed in memory only", systemImage: "memorychip")
            }
            .font(.callout)
            .foregroundStyle(.secondary)

            Divider()

            HStack(spacing: 12) {
                Button("Export Settings...") {
                    SettingsExporter.export(
                        settings: coordinator.settings,
                        appPreferences: coordinator.appPreferences
                    )
                }

                Button("Import Settings...") {
                    SettingsImporter.importSettings(
                        to: coordinator.settings,
                        appPreferences: coordinator.appPreferences
                    )
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
