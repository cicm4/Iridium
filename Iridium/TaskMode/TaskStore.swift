//
//  TaskStore.swift
//  Iridium
//
//  Manages the active task and task history.
//  Persists to ~/Library/Application Support/Iridium/Tasks/.
//

import Foundation
import Observation
import OSLog

@Observable
final class TaskStore: @unchecked Sendable {
    /// The currently active task, if any.
    private(set) var activeTask: TaskContext?

    /// History of all tasks (including the active one).
    private(set) var taskHistory: [TaskContext] = []

    /// Maximum number of tasks to keep in history.
    static let maxHistorySize = 20

    private let resolver: any TaskResolver
    private let fileURL: URL

    init(
        resolver: any TaskResolver = KeywordTaskResolver(),
        directory: URL? = nil
    ) {
        self.resolver = resolver
        let dir = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Iridium")
            .appendingPathComponent("Tasks")
        self.fileURL = dir.appendingPathComponent("tasks.json")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    /// Starts a new task. Resolves the description into category weights
    /// using the keyword resolver immediately, then optionally refines with AI.
    func startTask(description: String) async {
        // Deactivate current task
        if let index = taskHistory.firstIndex(where: { $0.id == activeTask?.id }) {
            taskHistory[index].isActive = false
        }

        // Resolve categories
        let categories = await resolver.resolve(description: description)

        let task = TaskContext(
            name: description,
            resolvedCategories: categories,
            isActive: true
        )

        activeTask = task
        taskHistory.insert(task, at: 0)

        // Trim history
        if taskHistory.count > Self.maxHistorySize {
            taskHistory = Array(taskHistory.prefix(Self.maxHistorySize))
        }

        save()
        Logger.learning.info("Started task: '\(description)' with \(categories.count) category weights")
    }

    /// Stops the active task.
    func stopTask() {
        guard let task = activeTask else { return }

        if let index = taskHistory.firstIndex(where: { $0.id == task.id }) {
            taskHistory[index].isActive = false
        }

        activeTask = nil
        save()
        Logger.learning.info("Stopped task: '\(task.name)'")
    }

    /// Resumes a task from history.
    func resumeTask(id: UUID) async {
        guard let task = taskHistory.first(where: { $0.id == id }) else { return }
        await startTask(description: task.name)
    }

    /// Removes a task from history.
    func removeFromHistory(id: UUID) {
        taskHistory.removeAll { $0.id == id }
        if activeTask?.id == id {
            activeTask = nil
        }
        save()
    }

    /// Loads tasks from disk.
    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let container = try JSONDecoder().decode(TasksContainer.self, from: data)
            taskHistory = container.history
            activeTask = taskHistory.first(where: { $0.isActive })
            Logger.learning.info("Loaded \(self.taskHistory.count) tasks from disk")
        } catch {
            Logger.learning.error("Failed to load tasks: \(error.localizedDescription)")
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    /// Saves tasks to disk.
    func save() {
        do {
            let container = TasksContainer(history: taskHistory)
            let data = try JSONEncoder().encode(container)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            Logger.learning.error("Failed to save tasks: \(error.localizedDescription)")
        }
    }
}

private struct TasksContainer: Codable {
    let history: [TaskContext]
}
