//
//  NotionIntegration.swift
//  Iridium
//
//  Fetches recent pages from the Notion API.
//  Signals: notion.recentPage, notion.recentDatabase
//

import Foundation
import OSLog

final class NotionIntegration: IridiumIntegration, @unchecked Sendable {
    let id = "notion"
    let name = "Notion"
    let integrationDescription = "Shows recent pages and databases from Notion"
    let iconSystemName = "doc.richtext"
    let requiredPermissions: [IntegrationPermission] = [.network(host: "api.notion.com")]
    let requiresToken = true

    private var token: String?
    private var cachedSignals: [IntegrationSignal] = []

    static let apiBaseURL = "https://api.notion.com/v1"
    static let notionVersion = "2022-06-28"

    func configure(context: IntegrationContext, token: String?) async throws {
        guard let token, !token.isEmpty else {
            throw IntegrationError.missingToken
        }
        self.token = token
    }

    func start() async {
        await fetchRecent()
    }

    func stop() async {
        cachedSignals = []
    }

    func currentSignals() async -> [IntegrationSignal] {
        cachedSignals
    }

    // MARK: - Private

    private func fetchRecent() async {
        guard let token else { return }

        // Search for recently edited pages
        var request = URLRequest(url: URL(string: "\(Self.apiBaseURL)/search")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(Self.notionVersion, forHTTPHeaderField: "Notion-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "sort": [
                "direction": "descending",
                "timestamp": "last_edited_time",
            ],
            "page_size": 5,
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                Logger.integrations.warning("Notion API returned non-200")
                return
            }

            let searchResult = try JSONDecoder().decode(NotionSearchResult.self, from: data)

            var signals: [IntegrationSignal] = []

            // Find most recent page
            if let recentPage = searchResult.results.first(where: { $0.object == "page" }) {
                let title = extractTitle(from: recentPage)
                signals.append(IntegrationSignal(namespace: id, key: "recentPage", value: String(title.prefix(64))))
            }

            // Find most recent database
            if let recentDB = searchResult.results.first(where: { $0.object == "database" }) {
                let title = extractTitle(from: recentDB)
                signals.append(IntegrationSignal(namespace: id, key: "recentDatabase", value: String(title.prefix(64))))
            }

            cachedSignals = signals
            Logger.integrations.debug("Notion: \(searchResult.results.count) recent items")
        } catch {
            Logger.integrations.error("Notion fetch failed: \(error.localizedDescription)")
        }
    }

    private func extractTitle(from item: NotionSearchItem) -> String {
        // Try to extract title from properties
        if let titleProp = item.properties?["title"],
           let titleArr = titleProp.title,
           let first = titleArr.first
        {
            return first.plainText ?? "Untitled"
        }

        // Fallback: try the title array directly
        if let titleArr = item.title, let first = titleArr.first {
            return first.plainText ?? "Untitled"
        }

        return "Untitled"
    }
}

// MARK: - Notion API Models

private struct NotionSearchResult: Codable {
    let results: [NotionSearchItem]
}

private struct NotionSearchItem: Codable {
    let object: String
    let id: String
    let properties: [String: NotionProperty]?
    let title: [NotionRichText]?
}

private struct NotionProperty: Codable {
    let title: [NotionRichText]?
}

private struct NotionRichText: Codable {
    let plainText: String?

    enum CodingKeys: String, CodingKey {
        case plainText = "plain_text"
    }
}
