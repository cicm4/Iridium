//
//  MenuBarPopoverView.swift
//  Iridium
//

import SwiftUI

struct MenuBarPopoverView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkle")
                    .foregroundStyle(.tint)
                Text("Iridium")
                    .font(.headline)
                Spacer()
                Toggle("", isOn: Bindable(coordinator.settings).isEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            .onChange(of: coordinator.settings.isEnabled) { _, newValue in
                if newValue {
                    coordinator.start()
                } else {
                    coordinator.stop()
                }
            }

            Divider()

            if coordinator.isRunning {
                Label("Active", systemImage: "circle.fill")
                    .foregroundStyle(.green)
                    .font(.callout)
            } else {
                Label("Paused", systemImage: "pause.circle")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }

            Divider()

            Button("Settings...") {
                openSettings()
            }

            Button("Quit Iridium") {
                NSApp.terminate(nil)
            }
        }
        .padding()
        .frame(width: 280)
    }
}
