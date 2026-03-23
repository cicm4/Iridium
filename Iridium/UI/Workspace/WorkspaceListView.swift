//
//  WorkspaceListView.swift
//  Iridium
//
//  Settings view for managing workspaces.
//

import SwiftUI

struct WorkspaceListView: View {
    @Environment(WorkspaceStore.self) private var store
    @State private var showingEditor = false
    @State private var editingWorkspace: Workspace?

    var body: some View {
        Form {
            Section("Workspaces") {
                if store.workspaces.isEmpty {
                    Text("No workspaces configured")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.workspaces) { workspace in
                        HStack {
                            Image(systemName: workspace.iconSystemName)
                                .foregroundStyle(.tint)
                                .frame(width: 20)
                            VStack(alignment: .leading) {
                                Text(workspace.name)
                                    .font(.body)
                                Text("\(workspace.apps.count) apps")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if workspace.isLearned {
                                Text("Learned")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                            Button {
                                editingWorkspace = workspace
                            } label: {
                                Image(systemName: "pencil")
                            }
                            .buttonStyle(.borderless)
                            Button {
                                store.remove(id: workspace.id)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }

                Button("Add Workspace...") {
                    showingEditor = true
                }
            }
        }
        .formStyle(.grouped)
        .sheet(isPresented: $showingEditor) {
            WorkspaceEditorView(workspace: nil) { workspace in
                store.add(workspace)
            }
        }
        .sheet(item: $editingWorkspace) { workspace in
            WorkspaceEditorView(workspace: workspace) { updated in
                store.update(updated)
            }
        }
    }
}
