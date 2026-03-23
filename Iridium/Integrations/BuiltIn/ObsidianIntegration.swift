//
//  ObsidianIntegration.swift
//  Iridium
//
//  Monitors Obsidian vault for recently modified notes.
//  Signals: obsidian.recentTopic, obsidian.activeVault
//  No API token needed — reads local filesystem.
//

import Foundation
import OSLog

final class ObsidianIntegration: IridiumIntegration, @unchecked Sendable {
    let id = "obsidian"
    let name = "Obsidian"
    let integrationDescription = "Detects recent notes and active vault from Obsidian"
    let iconSystemName = "note.text"
    let requiredPermissions: [IntegrationPermission] = [.fileRead(scope: "~/Library/Application Support/obsidian")]
    let requiresToken = false

    /// How recently a note must be modified to be considered "recent" (30 minutes).
    static let recentThreshold: TimeInterval = 30 * 60

    private var vaultPath: URL?
    private var vaultName: String?
    private var cachedSignals: [IntegrationSignal] = []

    func configure(context: IntegrationContext, token: String?) async throws {
        // Discover Obsidian vault from its config
        let obsidianConfig = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/obsidian/obsidian.json")

        guard FileManager.default.fileExists(atPath: obsidianConfig.path) else {
            throw IntegrationError.configurationError("Obsidian config not found. Is Obsidian installed?")
        }

        do {
            let data = try Data(contentsOf: obsidianConfig)
            let config = try JSONDecoder().decode(ObsidianConfig.self, from: data)
            if let firstVault = config.vaults.values.first {
                vaultPath = URL(fileURLWithPath: firstVault.path)
                vaultName = vaultPath?.lastPathComponent
            }
        } catch {
            Logger.integrations.warning("Failed to parse Obsidian config: \(error.localizedDescription)")
        }
    }

    func start() async {
        await scanRecentNotes()
    }

    func stop() async {
        cachedSignals = []
    }

    func currentSignals() async -> [IntegrationSignal] {
        // Refresh on each poll
        await scanRecentNotes()
        return cachedSignals
    }

    // MARK: - Private

    private func scanRecentNotes() async {
        var signals: [IntegrationSignal] = []

        if let name = vaultName {
            signals.append(IntegrationSignal(namespace: id, key: "activeVault", value: name))
        }

        guard let vaultPath else {
            cachedSignals = signals
            return
        }

        let now = Date()
        let recentNotes = findRecentMarkdownFiles(in: vaultPath, since: now.addingTimeInterval(-Self.recentThreshold))

        if let mostRecent = recentNotes.first {
            // Extract topic from filename (remove .md extension)
            let topic = mostRecent.deletingPathExtension().lastPathComponent
            signals.append(IntegrationSignal(namespace: id, key: "recentTopic", value: String(topic.prefix(64))))
        }

        cachedSignals = signals
        Logger.integrations.debug("Obsidian: vault=\(self.vaultName ?? "nil"), \(recentNotes.count) recent notes")
    }

    private func findRecentMarkdownFiles(in directory: URL, since cutoff: Date) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }

        var recent: [(url: URL, date: Date)] = []

        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "md" else { continue }

            guard let values = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]),
                  let modDate = values.contentModificationDate,
                  modDate > cutoff
            else { continue }

            recent.append((fileURL, modDate))
        }

        // Sort by most recent first
        return recent.sorted { $0.date > $1.date }.map(\.url)
    }
}

// MARK: - Obsidian Config Models

private struct ObsidianConfig: Codable {
    let vaults: [String: ObsidianVault]
}

private struct ObsidianVault: Codable {
    let path: String
}
