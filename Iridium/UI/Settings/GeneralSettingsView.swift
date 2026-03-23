//
//  GeneralSettingsView.swift
//  Iridium
//

import SwiftUI

struct GeneralSettingsView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        @Bindable var settings = coordinator.settings

        Form {
            Section("Suggestions") {
                Toggle("Enable Iridium", isOn: $settings.isEnabled)
                Toggle("Show suggestion panel", isOn: $settings.showSuggestions)

                Picker("Panel position", selection: $settings.suggestionPosition) {
                    ForEach(SuggestionPosition.allCases) { position in
                        Text(position.rawValue).tag(position)
                    }
                }

                HStack {
                    Text("Auto-dismiss after")
                    TextField("", value: $settings.autoDismissDelay, format: .number)
                        .frame(width: 50)
                    Text("seconds")
                }

                Slider(value: $settings.confidenceThreshold, in: 0.1...0.9, step: 0.1) {
                    Text("Confidence threshold: \(settings.confidenceThreshold, specifier: "%.1f")")
                }
            }

            Section("Intelligence") {
                Toggle("Enable Foundation Models (Tier 3)", isOn: $settings.enableFoundationModels)
                    .help("Use Apple's on-device LLM for nuanced content classification. All processing stays on your device.")

                Toggle("Learn from interactions", isOn: $settings.enablePersistentLearning)
                    .help("Remember which apps you select most often to improve future suggestions. Only stores app selection counts, never clipboard content.")
            }

            Section("Privacy") {
                Toggle("Respect Focus Mode", isOn: $settings.respectFocusMode)
                    .help("Hide suggestions when Do Not Disturb or a Focus mode is active.")
            }

            Section("Accessibility") {
                HStack {
                    if coordinator.accessibilityManager.isAccessibilityGranted {
                        Label("Accessibility Granted", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Label("Accessibility Not Granted", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                    Spacer()
                }

                if !coordinator.accessibilityManager.isAccessibilityGranted {
                    Text("Iridium needs accessibility permissions to manage windows and capture keyboard shortcuts.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Button("Request Accessibility Permission") {
                        coordinator.accessibilityManager.promptForPermission()
                    }

                    Button("Open System Settings") {
                        coordinator.accessibilityManager.openAccessibilityPreferences()
                    }
                }

                Button("Re-check Permission") {
                    coordinator.accessibilityManager.checkPermission()
                }
                .buttonStyle(.link)
            }
        }
        .formStyle(.grouped)
    }
}
