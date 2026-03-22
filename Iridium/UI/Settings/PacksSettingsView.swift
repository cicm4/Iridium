//
//  PacksSettingsView.swift
//  Iridium
//

import SwiftUI

struct PacksSettingsView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if coordinator.packRegistry.packs.isEmpty {
                ContentUnavailableView(
                    "No Packs Loaded",
                    systemImage: "puzzlepiece",
                    description: Text("Built-in packs load when Iridium starts.")
                )
            } else {
                List {
                    ForEach(coordinator.packRegistry.packs) { pack in
                        PackRow(
                            pack: pack,
                            isEnabled: coordinator.packRegistry.enabledPackIDs.contains(pack.id),
                            onToggle: { enabled in
                                coordinator.packRegistry.togglePack(id: pack.id, enabled: enabled)
                                coordinator.settings.enabledPackIDs = coordinator.packRegistry.enabledPackIDs
                            }
                        )
                    }
                }
            }
        }
    }
}

private struct PackRow: View {
    let pack: PackManifest
    let isEnabled: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(pack.name)
                    .font(.body)
                if let description = pack.description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("\(pack.triggers.count) trigger\(pack.triggers.count == 1 ? "" : "s") \u{2022} v\(pack.version)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { onToggle($0) }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}
