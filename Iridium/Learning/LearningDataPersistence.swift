//
//  LearningDataPersistence.swift
//  Iridium
//
//  Handles JSON serialization of adaptive weight data.
//  Writes are debounced (5-second window) to avoid excessive I/O.
//

import Foundation
import OSLog

final class LearningDataPersistence: @unchecked Sendable {
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// Debounce interval for writes.
    static let debounceInterval: TimeInterval = 5.0

    private var pendingSave: Task<Void, Never>?
    private let lock = NSLock()

    init(directory: URL? = nil) {
        let dir = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Iridium")
            .appendingPathComponent("LearningData")
        self.fileURL = dir.appendingPathComponent("weights.json")

        // Ensure directory exists
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    /// Loads weights from disk. Returns nil if file doesn't exist or is corrupt.
    func load() -> [ContentType: [String: BetaDistribution]]? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try decoder.decode(WeightsContainer.self, from: data)
            Logger.learning.info("Loaded weights from \(self.fileURL.lastPathComponent)")
            return decoded.weights
        } catch {
            Logger.learning.error("Failed to load weights: \(error.localizedDescription). Starting fresh.")
            // Remove corrupt file
            try? FileManager.default.removeItem(at: fileURL)
            return nil
        }
    }

    /// Saves weights to disk with debouncing.
    func save(_ weights: [ContentType: [String: BetaDistribution]]) {
        lock.lock()
        pendingSave?.cancel()
        let task = Task.detached { [weak self] in
            try? await Task.sleep(for: .seconds(LearningDataPersistence.debounceInterval))
            guard !Task.isCancelled else { return }
            self?.writeImmediately(weights)
        }
        pendingSave = task
        lock.unlock()
    }

    /// Writes immediately without debouncing. Used for shutdown.
    func writeImmediately(_ weights: [ContentType: [String: BetaDistribution]]) {
        do {
            let container = WeightsContainer(weights: weights)
            let data = try encoder.encode(container)
            try data.write(to: fileURL, options: .atomic)
            Logger.learning.debug("Saved weights to \(self.fileURL.lastPathComponent)")
        } catch {
            Logger.learning.error("Failed to save weights: \(error.localizedDescription)")
        }
    }

    /// Deletes the weights file.
    func deleteAll() {
        try? FileManager.default.removeItem(at: fileURL)
        Logger.learning.info("Deleted weights file")
    }
}

// MARK: - Codable Container

private struct WeightsContainer: Codable {
    let weights: [ContentType: [String: BetaDistribution]]
}
