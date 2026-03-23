//
//  WorkspaceStore.swift
//  Iridium
//
//  CRUD operations for workspaces with disk persistence.
//

import Foundation
import Observation
import OSLog

@Observable
final class WorkspaceStore: @unchecked Sendable {
    private(set) var workspaces: [Workspace] = []
    private(set) var activeWorkspaceID: UUID?

    private let fileURL: URL

    var activeWorkspace: Workspace? {
        workspaces.first { $0.id == activeWorkspaceID }
    }

    init(directory: URL? = nil) {
        let dir = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Iridium")
            .appendingPathComponent("Workspaces")
        self.fileURL = dir.appendingPathComponent("workspaces.json")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    // MARK: - CRUD

    func add(_ workspace: Workspace) {
        workspaces.append(workspace)
        save()
        Logger.windowManager.info("Added workspace: '\(workspace.name)' with \(workspace.apps.count) apps")
    }

    func remove(id: UUID) {
        workspaces.removeAll { $0.id == id }
        if activeWorkspaceID == id {
            activeWorkspaceID = nil
        }
        save()
    }

    func update(_ workspace: Workspace) {
        guard let index = workspaces.firstIndex(where: { $0.id == workspace.id }) else { return }
        workspaces[index] = workspace
        save()
    }

    func setActive(id: UUID?) {
        activeWorkspaceID = id
    }

    // MARK: - Persistence

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            workspaces = try JSONDecoder().decode([Workspace].self, from: data)
            Logger.windowManager.info("Loaded \(self.workspaces.count) workspaces")
        } catch {
            Logger.windowManager.error("Failed to load workspaces: \(error.localizedDescription)")
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(workspaces)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            Logger.windowManager.error("Failed to save workspaces: \(error.localizedDescription)")
        }
    }
}
