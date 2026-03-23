//
//  AppPreferencesSettingsView.swift
//  Iridium
//

import SwiftUI
import UniformTypeIdentifiers

struct AppPreferencesSettingsView: View {
    @Bindable var appPreferences: AppPreferences

    @State private var newPinnedID: String = ""
    @State private var newExcludedID: String = ""

    var body: some View {
        Form {
            Section("Pinned Apps") {
                Text("Pinned apps are boosted in suggestion rankings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(Array(appPreferences.pinnedBundleIDs).sorted(), id: \.self) { bundleID in
                    HStack {
                        Text(bundleID)
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                        Button(role: .destructive) {
                            appPreferences.pinnedBundleIDs.remove(bundleID)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                        }
                        .buttonStyle(.borderless)
                    }
                }

                HStack {
                    TextField("Bundle ID", text: $newPinnedID)
                        .textFieldStyle(.roundedBorder)
                    Button("Add") {
                        let trimmed = newPinnedID.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        appPreferences.pinnedBundleIDs.insert(trimmed)
                        newPinnedID = ""
                    }
                    .disabled(newPinnedID.trimmingCharacters(in: .whitespaces).isEmpty)

                    Button("Browse...") {
                        browseForApp { bundleID in
                            appPreferences.pinnedBundleIDs.insert(bundleID)
                        }
                    }
                }
            }

            Section("Excluded Apps") {
                Text("Excluded apps are never suggested.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(Array(appPreferences.excludedBundleIDs).sorted(), id: \.self) { bundleID in
                    HStack {
                        Text(bundleID)
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                        Button(role: .destructive) {
                            appPreferences.excludedBundleIDs.remove(bundleID)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                        }
                        .buttonStyle(.borderless)
                    }
                }

                HStack {
                    TextField("Bundle ID", text: $newExcludedID)
                        .textFieldStyle(.roundedBorder)
                    Button("Add") {
                        let trimmed = newExcludedID.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        appPreferences.excludedBundleIDs.insert(trimmed)
                        newExcludedID = ""
                    }
                    .disabled(newExcludedID.trimmingCharacters(in: .whitespaces).isEmpty)

                    Button("Browse...") {
                        browseForApp { bundleID in
                            appPreferences.excludedBundleIDs.insert(bundleID)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func browseForApp(completion: @escaping (String) -> Void) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.message = "Select an application"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            if let bundle = Bundle(url: url), let bundleID = bundle.bundleIdentifier {
                completion(bundleID)
            }
        }
    }
}
