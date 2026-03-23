//
//  WorkspaceMigratorTests.swift
//  IridiumTests
//

import Foundation
import Testing
@testable import Iridium

@MainActor
struct WorkspaceMigratorTests {
    @Test("Migrates workspace apps to co-occurrences")
    func migratesCoOccurrences() {
        let learner = WorkspaceLearner()
        let migrator = WorkspaceMigrator()

        let workspace = Workspace(
            id: .init(),
            name: "Dev",
            apps: [
                WorkspaceApp(bundleID: "com.apple.dt.Xcode", region: .leftHalf),
                WorkspaceApp(bundleID: "com.apple.Terminal", region: .rightHalf),
                WorkspaceApp(bundleID: "com.apple.Safari", region: .fullscreen),
            ]
        )

        migrator.migrate(from: [workspace], into: learner)

        // Each pair should have threshold count
        let xcodeTerminal = learner.coOccurrences["com.apple.dt.Xcode"]?["com.apple.Terminal"] ?? 0
        #expect(xcodeTerminal >= WorkspaceLearner.suggestionThreshold,
                "Xcode-Terminal co-occurrence should be at least threshold, got \(xcodeTerminal)")
    }

    @Test("Migrates layout regions")
    func migratesLayoutRegions() {
        let learner = WorkspaceLearner()
        let migrator = WorkspaceMigrator()

        let workspace = Workspace(
            id: .init(),
            name: "Dev",
            apps: [
                WorkspaceApp(bundleID: "com.apple.dt.Xcode", region: .leftHalf),
                WorkspaceApp(bundleID: "com.apple.Terminal", region: .rightHalf),
            ]
        )

        migrator.migrate(from: [workspace], into: learner)

        let layout = learner.preferredLayout(forPair: "com.apple.dt.Xcode", "com.apple.Terminal")
        #expect(layout != nil, "Layout preference should be migrated")
        #expect(layout?.count == 3, "Should have 3 records (migration threshold)")
    }

    @Test("Handles empty workspace list")
    func handlesEmptyWorkspaces() {
        let learner = WorkspaceLearner()
        let migrator = WorkspaceMigrator()

        migrator.migrate(from: [], into: learner)

        #expect(learner.coOccurrences.isEmpty)
    }

    @Test("Handles workspace with single app")
    func handlesSingleAppWorkspace() {
        let learner = WorkspaceLearner()
        let migrator = WorkspaceMigrator()

        let workspace = Workspace(
            id: .init(),
            name: "Solo",
            apps: [WorkspaceApp(bundleID: "com.apple.dt.Xcode", region: .fullscreen)]
        )

        migrator.migrate(from: [workspace], into: learner)

        // Single app workspace should not create any co-occurrences
        #expect(learner.coOccurrences.isEmpty)
    }
}
