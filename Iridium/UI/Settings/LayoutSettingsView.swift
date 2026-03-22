//
//  LayoutSettingsView.swift
//  Iridium
//

import SwiftUI

struct LayoutSettingsView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Accessibility Permission")
                    .font(.headline)
                Spacer()
                if coordinator.accessibilityManager.isAccessibilityGranted {
                    Label("Granted", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.callout)
                } else {
                    Button("Grant Access") {
                        coordinator.accessibilityManager.promptForPermission()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            if !coordinator.accessibilityManager.isAccessibilityGranted {
                Text("Window management requires Accessibility permission. Iridium can suggest apps without it, but cannot move or resize windows.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }

            Divider()

            Text("Layout Presets")
                .font(.headline)
                .padding(.horizontal)

            List {
                ForEach(coordinator.windowManager.presetStore.presets) { preset in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(preset.name)
                                .font(.body)
                            if let hotkey = preset.hotkey {
                                Text(hotkey)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text("\(preset.regions.count) region\(preset.regions.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}
