//
//  WorkspaceEditorView.swift
//  Iridium
//
//  Create or edit a workspace: pick apps, set name and layout regions.
//

import SwiftUI

struct WorkspaceEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var apps: [WorkspaceApp]
    @State private var newBundleID: String = ""

    let existingWorkspace: Workspace?
    let onSave: (Workspace) -> Void

    init(workspace: Workspace?, onSave: @escaping (Workspace) -> Void) {
        self.existingWorkspace = workspace
        self.onSave = onSave
        _name = State(initialValue: workspace?.name ?? "")
        _apps = State(initialValue: workspace?.apps ?? [])
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(existingWorkspace == nil ? "New Workspace" : "Edit Workspace")
                .font(.headline)

            TextField("Workspace Name", text: $name)
                .textFieldStyle(.roundedBorder)

            Divider()

            // App list
            VStack(alignment: .leading, spacing: 8) {
                Text("Apps")
                    .font(.callout.weight(.medium))

                ForEach(Array(apps.enumerated()), id: \.offset) { index, app in
                    HStack {
                        Text(app.bundleID)
                            .font(.caption.monospaced())
                            .lineLimit(1)
                        Spacer()

                        // Layout region selector
                        Picker("", selection: Binding(
                            get: { layoutLabel(for: apps[index].region) },
                            set: { apps[index].region = region(for: $0) }
                        )) {
                            Text("Full").tag("full")
                            Text("Left").tag("left")
                            Text("Right").tag("right")
                            Text("Top Left").tag("topLeft")
                            Text("Top Right").tag("topRight")
                            Text("Bottom Left").tag("bottomLeft")
                            Text("Bottom Right").tag("bottomRight")
                        }
                        .frame(width: 100)

                        Button {
                            apps.remove(at: index)
                        } label: {
                            Image(systemName: "minus.circle")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                }

                HStack {
                    TextField("Bundle ID (e.g., com.apple.dt.Xcode)", text: $newBundleID)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { addApp() }
                    Button("Add") { addApp() }
                        .disabled(newBundleID.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            Spacer()

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") { saveWorkspace() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || apps.isEmpty)
            }
        }
        .padding()
        .frame(width: 480, height: 400)
    }

    private func addApp() {
        let bundleID = newBundleID.trimmingCharacters(in: .whitespaces)
        guard !bundleID.isEmpty, !apps.contains(where: { $0.bundleID == bundleID }) else { return }
        apps.append(WorkspaceApp(bundleID: bundleID))
        newBundleID = ""
    }

    private func saveWorkspace() {
        let workspace = Workspace(
            id: existingWorkspace?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            apps: apps,
            spaceIndex: existingWorkspace?.spaceIndex,
            iconSystemName: existingWorkspace?.iconSystemName ?? "square.grid.2x2",
            isLearned: existingWorkspace?.isLearned ?? false
        )
        onSave(workspace)
        dismiss()
    }

    private func layoutLabel(for region: LayoutPreset.Region) -> String {
        if region.width == 1 && region.height == 1 { return "full" }
        if region.x == 0 && region.width == 0.5 && region.height == 1 { return "left" }
        if region.x == 0.5 && region.width == 0.5 && region.height == 1 { return "right" }
        if region.x == 0 && region.y == 0 && region.width == 0.5 && region.height == 0.5 { return "topLeft" }
        if region.x == 0.5 && region.y == 0 && region.width == 0.5 && region.height == 0.5 { return "topRight" }
        if region.x == 0 && region.y == 0.5 && region.width == 0.5 && region.height == 0.5 { return "bottomLeft" }
        if region.x == 0.5 && region.y == 0.5 && region.width == 0.5 && region.height == 0.5 { return "bottomRight" }
        return "full"
    }

    private func region(for label: String) -> LayoutPreset.Region {
        switch label {
        case "left": return .init(x: 0, y: 0, width: 0.5, height: 1)
        case "right": return .init(x: 0.5, y: 0, width: 0.5, height: 1)
        case "topLeft": return .init(x: 0, y: 0, width: 0.5, height: 0.5)
        case "topRight": return .init(x: 0.5, y: 0, width: 0.5, height: 0.5)
        case "bottomLeft": return .init(x: 0, y: 0.5, width: 0.5, height: 0.5)
        case "bottomRight": return .init(x: 0.5, y: 0.5, width: 0.5, height: 0.5)
        default: return .init(x: 0, y: 0, width: 1, height: 1)
        }
    }
}
