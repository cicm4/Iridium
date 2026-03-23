//
//  TaskStoreTests.swift
//  IridiumTests
//

import Foundation
import Testing
@testable import Iridium

@Suite("TaskStore")
struct TaskStoreTests {

    private func tempDir() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("IridiumTests-\(UUID().uuidString)")
    }

    @Test("Start task sets active task")
    func startTaskSetsActive() async {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = TaskStore(directory: dir)
        await store.startTask(description: "coding project")

        #expect(store.activeTask != nil)
        #expect(store.activeTask?.name == "coding project")
        #expect(store.activeTask?.isActive == true)
    }

    @Test("Start task resolves categories")
    func startTaskResolvesCategories() async {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = TaskStore(directory: dir)
        await store.startTask(description: "video editing project")

        let task = store.activeTask
        #expect(task != nil)
        #expect(task?.resolvedCategories[.media] != nil, "Should resolve 'video' to media")
        #expect(task?.resolvedCategories[.creativity] != nil, "Should resolve 'editing' to creativity")
    }

    @Test("Stop task clears active task")
    func stopTaskClearsActive() async {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = TaskStore(directory: dir)
        await store.startTask(description: "test")
        #expect(store.activeTask != nil)

        store.stopTask()
        #expect(store.activeTask == nil)
    }

    @Test("Task history tracks previous tasks")
    func taskHistoryTracks() async {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = TaskStore(directory: dir)
        await store.startTask(description: "task 1")
        await store.startTask(description: "task 2")
        await store.startTask(description: "task 3")

        #expect(store.taskHistory.count == 3)
        #expect(store.taskHistory[0].name == "task 3")
        #expect(store.taskHistory[1].name == "task 2")
        #expect(store.taskHistory[2].name == "task 1")
    }

    @Test("Starting new task deactivates old task")
    func newTaskDeactivatesOld() async {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = TaskStore(directory: dir)
        await store.startTask(description: "old task")
        let oldID = store.activeTask?.id

        await store.startTask(description: "new task")

        let oldInHistory = store.taskHistory.first(where: { $0.id == oldID })
        #expect(oldInHistory?.isActive == false, "Old task should be deactivated")
        #expect(store.activeTask?.name == "new task")
    }

    @Test("Persistence round-trip")
    func persistenceRoundTrip() async {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store1 = TaskStore(directory: dir)
        await store1.startTask(description: "persistent task")
        store1.save()

        let store2 = TaskStore(directory: dir)
        store2.load()

        #expect(store2.taskHistory.count == 1)
        #expect(store2.activeTask?.name == "persistent task")
    }

    @Test("Remove from history")
    func removeFromHistory() async {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = TaskStore(directory: dir)
        await store.startTask(description: "task to remove")
        let id = store.activeTask!.id

        store.removeFromHistory(id: id)
        #expect(store.taskHistory.isEmpty)
        #expect(store.activeTask == nil)
    }

    @Test("History capped at maxHistorySize")
    func historyCapped() async {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = TaskStore(directory: dir)
        for i in 0..<25 {
            await store.startTask(description: "task \(i)")
        }

        #expect(store.taskHistory.count <= TaskStore.maxHistorySize)
    }
}
