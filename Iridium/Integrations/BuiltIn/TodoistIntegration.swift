//
//  TodoistIntegration.swift
//  Iridium
//
//  Fetches tasks from Todoist REST API.
//  Signals: todoist.dueToday, todoist.overdue, todoist.currentProject
//

import Foundation
import OSLog

final class TodoistIntegration: IridiumIntegration, @unchecked Sendable {
    let id = "todoist"
    let name = "Todoist"
    let integrationDescription = "Shows task counts and current project from Todoist"
    let iconSystemName = "checklist"
    let requiredPermissions: [IntegrationPermission] = [.network(host: "api.todoist.com")]
    let requiresToken = true

    private var token: String?
    private var cachedSignals: [IntegrationSignal] = []
    private var pollTimer: Timer?

    static let pollInterval: TimeInterval = 300  // 5 minutes
    static let apiBaseURL = "https://api.todoist.com/rest/v2"

    func configure(context: IntegrationContext, token: String?) async throws {
        guard let token, !token.isEmpty else {
            throw IntegrationError.missingToken
        }
        self.token = token
    }

    func start() async {
        await fetchTasks()
    }

    func stop() async {
        pollTimer?.invalidate()
        pollTimer = nil
        cachedSignals = []
    }

    func currentSignals() async -> [IntegrationSignal] {
        cachedSignals
    }

    // MARK: - Private

    private func fetchTasks() async {
        guard let token else { return }

        var request = URLRequest(url: URL(string: "\(Self.apiBaseURL)/tasks?filter=today|overdue")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                Logger.integrations.warning("Todoist API returned non-200 status")
                return
            }

            let tasks = try JSONDecoder().decode([TodoistTask].self, from: data)

            let today = tasks.filter { !isOverdue($0) }
            let overdue = tasks.filter { isOverdue($0) }

            // Find most common project
            let projectCounts = Dictionary(grouping: tasks, by: { $0.projectId })
            let topProject = projectCounts.max(by: { $0.value.count < $1.value.count })

            var signals: [IntegrationSignal] = [
                IntegrationSignal(namespace: id, key: "dueToday", value: "\(today.count)"),
                IntegrationSignal(namespace: id, key: "overdue", value: "\(overdue.count)"),
            ]

            if let projectId = topProject?.key {
                signals.append(IntegrationSignal(namespace: id, key: "currentProject", value: projectId))
            }

            cachedSignals = signals
            Logger.integrations.debug("Todoist: \(today.count) due today, \(overdue.count) overdue")
        } catch {
            Logger.integrations.error("Todoist fetch failed: \(error.localizedDescription)")
        }
    }

    private func isOverdue(_ task: TodoistTask) -> Bool {
        guard let due = task.due, let dateStr = due.date else { return false }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let dueDate = formatter.date(from: dateStr) else { return false }
        return dueDate < Calendar.current.startOfDay(for: Date())
    }
}

// MARK: - API Models

private struct TodoistTask: Codable {
    let id: String
    let content: String
    let projectId: String
    let due: TodoistDue?

    enum CodingKeys: String, CodingKey {
        case id, content, due
        case projectId = "project_id"
    }
}

private struct TodoistDue: Codable {
    let date: String?
    let isRecurring: Bool?

    enum CodingKeys: String, CodingKey {
        case date
        case isRecurring = "is_recurring"
    }
}

enum IntegrationError: Error, LocalizedError {
    case missingToken
    case configurationError(String)

    var errorDescription: String? {
        switch self {
        case .missingToken: return "API token is required"
        case .configurationError(let msg): return msg
        }
    }
}
