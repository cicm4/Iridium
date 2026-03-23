//
//  WorkspaceModel.swift
//  Iridium
//
//  A workspace is a named group of apps with saved layout positions.
//  Workspaces can be manually created or learned from usage patterns.
//

import Foundation

struct Workspace: Codable, Sendable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var apps: [WorkspaceApp]
    var spaceIndex: Int?
    var iconSystemName: String
    var isLearned: Bool

    init(
        id: UUID = UUID(),
        name: String,
        apps: [WorkspaceApp],
        spaceIndex: Int? = nil,
        iconSystemName: String = "square.grid.2x2",
        isLearned: Bool = false
    ) {
        self.id = id
        self.name = name
        self.apps = apps
        self.spaceIndex = spaceIndex
        self.iconSystemName = iconSystemName
        self.isLearned = isLearned
    }

    /// Bundle IDs of all apps in this workspace.
    var bundleIDs: Set<String> {
        Set(apps.map(\.bundleID))
    }

    /// How many of this workspace's apps are currently in the given running set.
    func runningCount(in runningApps: Set<String>) -> Int {
        apps.filter { runningApps.contains($0.bundleID) }.count
    }
}

struct WorkspaceApp: Codable, Sendable, Equatable, Identifiable {
    var id: String { bundleID }
    let bundleID: String
    var region: LayoutPreset.Region

    init(bundleID: String, region: LayoutPreset.Region = .init(x: 0, y: 0, width: 1, height: 1)) {
        self.bundleID = bundleID
        self.region = region
    }
}
