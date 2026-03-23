//
//  PredictiveWorkspaceSettingsView.swift
//  Iridium
//

import SwiftUI

struct PredictiveWorkspaceSettingsView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        Form {
            Section {
                Toggle("Enable Predictive Window Manager", isOn: Bindable(coordinator.settings).enablePredictiveWorkspace)

                Text("Press Hyper+Space (Ctrl+Option+Shift+Cmd+Space) to predict which app you need next and arrange it on screen.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Privacy") {
                Toggle("Screen Content Analysis", isOn: Bindable(coordinator.settings).enableScreenOCR)

                Text("When enabled, Iridium reads text from your focused window to improve predictions. All processing happens on-device. Requires screen recording permission.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Learned Patterns") {
                let topPairs = coordinator.workspaceLearner.topCoOccurrencePairs(limit: 5)
                if topPairs.isEmpty {
                    Text("No patterns learned yet. Keep using your apps and Iridium will learn which apps you use together.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(topPairs, id: \.0) { pair in
                        HStack {
                            Text(coordinator.installedAppRegistry.name(for: pair.0) ?? pair.0)
                            Image(systemName: "arrow.left.arrow.right")
                                .foregroundStyle(.secondary)
                            Text(coordinator.installedAppRegistry.name(for: pair.1) ?? pair.1)
                            Spacer()
                            Text("\(pair.2)x")
                                .foregroundStyle(.tertiary)
                                .font(.caption)
                        }
                        .font(.callout)
                    }
                }

                Button("Reset Learned Preferences") {
                    coordinator.workspaceLearner.reset()
                }
                .foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
    }
}
