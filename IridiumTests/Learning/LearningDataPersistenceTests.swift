//
//  LearningDataPersistenceTests.swift
//  IridiumTests
//

import Foundation
import Testing
@testable import Iridium

@Suite("LearningDataPersistence")
struct LearningDataPersistenceTests {

    private func tempDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("IridiumTests-\(UUID().uuidString)")
    }

    @Test("Save and load round-trip preserves data")
    func saveLoadRoundTrip() {
        let dir = tempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        let persistence = LearningDataPersistence(directory: dir)

        var dist = BetaDistribution.uniformPrior
        dist.update(selected: true)
        dist.update(selected: true)

        let weights: [ContentType: [String: BetaDistribution]] = [
            .code: ["com.apple.dt.Xcode": dist],
            .url: ["com.apple.Safari": .uniformPrior],
        ]

        persistence.writeImmediately(weights)

        let loaded = persistence.load()
        #expect(loaded != nil, "Should load saved data")
        #expect(loaded?[.code]?["com.apple.dt.Xcode"]?.alpha == dist.alpha)
        #expect(loaded?[.code]?["com.apple.dt.Xcode"]?.beta == dist.beta)
        #expect(loaded?[.url]?["com.apple.Safari"]?.mean == 0.5)
    }

    @Test("Load returns nil when no file exists")
    func loadReturnsNilForMissing() {
        let dir = tempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        let persistence = LearningDataPersistence(directory: dir)
        let loaded = persistence.load()
        #expect(loaded == nil, "Should return nil for non-existent file")
    }

    @Test("Corruption recovery returns nil and removes corrupt file")
    func corruptionRecovery() throws {
        let dir = tempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let fileURL = dir.appendingPathComponent("weights.json")
        try "not json".data(using: .utf8)!.write(to: fileURL)

        let persistence = LearningDataPersistence(directory: dir)
        let loaded = persistence.load()
        #expect(loaded == nil, "Should return nil for corrupt file")
        #expect(!FileManager.default.fileExists(atPath: fileURL.path), "Should remove corrupt file")
    }

    @Test("deleteAll removes the file")
    func deleteAll() throws {
        let dir = tempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        let persistence = LearningDataPersistence(directory: dir)
        persistence.writeImmediately([.code: ["x": .uniformPrior]])

        let fileURL = dir.appendingPathComponent("weights.json")
        #expect(FileManager.default.fileExists(atPath: fileURL.path))

        persistence.deleteAll()
        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
    }
}
