//
//  WorkspaceStoreTests.swift
//  IridiumTests
//

import Foundation
import Testing
@testable import Iridium

@Suite("WorkspaceStore")
struct WorkspaceStoreTests {

    private func tempDir() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("IridiumTests-\(UUID().uuidString)")
    }

    @Test("Add workspace persists")
    func addWorkspace() {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = WorkspaceStore(directory: dir)
        let ws = Workspace(name: "Dev", apps: [WorkspaceApp(bundleID: "com.test.app")])
        store.add(ws)

        #expect(store.workspaces.count == 1)
        #expect(store.workspaces[0].name == "Dev")
    }

    @Test("Remove workspace")
    func removeWorkspace() {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = WorkspaceStore(directory: dir)
        let ws = Workspace(name: "Dev", apps: [WorkspaceApp(bundleID: "com.test.app")])
        store.add(ws)
        store.remove(id: ws.id)

        #expect(store.workspaces.isEmpty)
    }

    @Test("Update workspace")
    func updateWorkspace() {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = WorkspaceStore(directory: dir)
        var ws = Workspace(name: "Dev", apps: [WorkspaceApp(bundleID: "com.test.app")])
        store.add(ws)

        ws.name = "Development"
        store.update(ws)

        #expect(store.workspaces[0].name == "Development")
    }

    @Test("Persistence round-trip")
    func persistenceRoundTrip() {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store1 = WorkspaceStore(directory: dir)
        store1.add(Workspace(name: "WS1", apps: [WorkspaceApp(bundleID: "com.a")]))
        store1.add(Workspace(name: "WS2", apps: [
            WorkspaceApp(bundleID: "com.b"),
            WorkspaceApp(bundleID: "com.c"),
        ]))

        let store2 = WorkspaceStore(directory: dir)
        store2.load()

        #expect(store2.workspaces.count == 2)
        #expect(store2.workspaces[0].name == "WS1")
        #expect(store2.workspaces[1].apps.count == 2)
    }

    @Test("Active workspace tracking")
    func activeWorkspace() {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = WorkspaceStore(directory: dir)
        let ws = Workspace(name: "Dev", apps: [WorkspaceApp(bundleID: "com.test")])
        store.add(ws)

        #expect(store.activeWorkspace == nil)

        store.setActive(id: ws.id)
        #expect(store.activeWorkspace?.name == "Dev")

        store.setActive(id: nil)
        #expect(store.activeWorkspace == nil)
    }

    @Test("Removing active workspace clears activeWorkspaceID")
    func removeActiveClearsID() {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = WorkspaceStore(directory: dir)
        let ws = Workspace(name: "Dev", apps: [WorkspaceApp(bundleID: "com.test")])
        store.add(ws)
        store.setActive(id: ws.id)
        store.remove(id: ws.id)

        #expect(store.activeWorkspaceID == nil)
    }
}
