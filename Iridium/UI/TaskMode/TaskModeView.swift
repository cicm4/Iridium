//
//  TaskModeView.swift
//  Iridium
//
//  Task mode section for the menu bar popover.
//  Lets users define a task to bias suggestions.
//

import SwiftUI

struct TaskModeView: View {
    @Environment(TaskStore.self) private var taskStore
    @State private var taskDescription = ""
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "target")
                        .foregroundStyle(taskStore.activeTask != nil ? .orange : .secondary)
                    Text("Task Mode")
                        .font(.callout.weight(.medium))
                    Spacer()
                    if let task = taskStore.activeTask {
                        Text(task.name)
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .lineLimit(1)
                    }
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(AccessibilityID.TaskMode.header)
            .accessibilityLabel(taskStore.activeTask != nil ? "Task Mode, active: \(taskStore.activeTask!.name)" : "Task Mode, no active task")

            if isExpanded {
                if let task = taskStore.activeTask {
                    // Active task display
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.name)
                                .font(.callout)
                            Text(categorySummary(task))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Stop") {
                            taskStore.stopTask()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .accessibilityIdentifier(AccessibilityID.TaskMode.stopButton)
                    }
                    .padding(.vertical, 4)
                } else {
                    // Task entry
                    HStack {
                        TextField("What are you working on?", text: $taskDescription)
                            .textFieldStyle(.roundedBorder)
                            .controlSize(.small)
                            .accessibilityIdentifier(AccessibilityID.TaskMode.taskInput)
                            .onSubmit {
                                startTask()
                            }
                        Button("Start") {
                            startTask()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(taskDescription.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityIdentifier(AccessibilityID.TaskMode.startButton)
                    }
                }

                // Recent tasks
                if !taskStore.taskHistory.isEmpty {
                    Divider()
                    Text("Recent")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    ForEach(taskStore.taskHistory.prefix(3)) { task in
                        if task.id != taskStore.activeTask?.id {
                            Button {
                                Task {
                                    await taskStore.resumeTask(id: task.id)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.caption2)
                                    Text(task.name)
                                        .font(.caption)
                                        .lineLimit(1)
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func startTask() {
        let description = taskDescription.trimmingCharacters(in: .whitespaces)
        guard !description.isEmpty else { return }
        Task {
            await taskStore.startTask(description: description)
        }
        taskDescription = ""
    }

    private func categorySummary(_ task: TaskContext) -> String {
        let top = task.resolvedCategories
            .sorted { $0.value > $1.value }
            .prefix(2)
            .map { $0.key.rawValue.capitalized }
        return top.isEmpty ? "General" : top.joined(separator: ", ")
    }
}
