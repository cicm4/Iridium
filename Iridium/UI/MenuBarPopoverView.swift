//
//  MenuBarPopoverView.swift
//  Iridium
//

import SwiftUI

struct MenuBarPopoverView: View {
    @Environment(AppCoordinator.self) private var coordinator

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
                    .accessibilityIdentifier(AccessibilityID.MenuBar.enableToggle)
                    .accessibilityLabel("Enable Iridium")
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
                    .accessibilityIdentifier(AccessibilityID.MenuBar.statusLabel)
                    .accessibilityLabel("Iridium is active")
            } else {
                Label("Paused", systemImage: "pause.circle")
                    .foregroundStyle(.secondary)
                    .font(.callout)
                    .accessibilityIdentifier(AccessibilityID.MenuBar.statusLabel)
                    .accessibilityLabel("Iridium is paused")
            }

            if coordinator.settings.enableTaskMode {
                Divider()

                TaskModeView()
                    .environment(coordinator.taskStore)
            }

            Divider()

            SettingsLink {
                Text("Settings...")
            }
            .buttonStyle(.plain)

            Button("Quit Iridium") {
                NSApp.terminate(nil)
            }
            .accessibilityIdentifier(AccessibilityID.MenuBar.quitButton)
        }
        .padding()
        .frame(width: 280)
    }
}
