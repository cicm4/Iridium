//
//  GeneralSettingsView.swift
//  Iridium
//

import ServiceManagement
import SwiftUI

struct GeneralSettingsView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        @Bindable var settings = coordinator.settings

        Form {
            Section("Startup") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .accessibilityIdentifier(AccessibilityID.Settings.launchAtLoginToggle)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            // Revert toggle if registration failed
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }
            }

            Section("Suggestions") {
                Toggle("Enable Iridium", isOn: $settings.isEnabled)
                    .accessibilityIdentifier(AccessibilityID.Settings.enableIridiumToggle)
                Toggle("Show suggestion panel", isOn: $settings.showSuggestions)
                    .accessibilityIdentifier(AccessibilityID.Settings.showSuggestionsToggle)

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
                    .accessibilityIdentifier(AccessibilityID.Settings.foundationModelsToggle)
                    .help("Use Apple's on-device LLM for nuanced content classification. All processing stays on your device.")

                Toggle("Learn from interactions", isOn: $settings.enablePersistentLearning)
                    .accessibilityIdentifier(AccessibilityID.Settings.persistentLearningToggle)
                    .help("Remember which apps you select most often to improve future suggestions. Only stores app selection counts, never clipboard content.")
            }

            Section("Privacy") {
                Toggle("Respect Focus Mode", isOn: $settings.respectFocusMode)
                    .accessibilityIdentifier(AccessibilityID.Settings.focusModeToggle)
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
