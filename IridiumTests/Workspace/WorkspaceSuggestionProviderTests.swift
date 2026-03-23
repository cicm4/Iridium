//
//  WorkspaceSuggestionProviderTests.swift
//  IridiumTests
//

import Foundation
import Testing
@testable import Iridium

@Suite("WorkspaceSuggestionProvider")
struct WorkspaceSuggestionProviderTests {

    let provider = WorkspaceSuggestionProvider()

    @Test("Workspace suggested when 2+ apps are running")
    func suggestedWhenAppsRunning() {
        let workspace = Workspace(
            name: "Dev",
            apps: [
                WorkspaceApp(bundleID: "com.apple.dt.Xcode"),
                WorkspaceApp(bundleID: "com.apple.Safari"),
                WorkspaceApp(bundleID: "com.apple.Terminal"),
            ]
        )

        let running: Set<String> = ["com.apple.dt.Xcode", "com.apple.Safari"]
        let suggestions = provider.evaluate(workspaces: [workspace], runningApps: running)

        #expect(suggestions.count == 1, "Should suggest workspace with 2 running apps")
        #expect(suggestions[0].bundleID.contains(workspace.id.uuidString))
    }

    @Test("Workspace not suggested when fewer than 2 apps running")
    func notSuggestedWithOneApp() {
        let workspace = Workspace(
            name: "Dev",
            apps: [
                WorkspaceApp(bundleID: "com.apple.dt.Xcode"),
                WorkspaceApp(bundleID: "com.apple.Safari"),
            ]
        )

        let running: Set<String> = ["com.apple.dt.Xcode"]  // Only 1 app
        let suggestions = provider.evaluate(workspaces: [workspace], runningApps: running)

        #expect(suggestions.isEmpty, "Should not suggest with only 1 running app")
    }

    @Test("Active workspace is not re-suggested")
    func activeNotReSuggested() {
        let workspace = Workspace(
            name: "Dev",
            apps: [
                WorkspaceApp(bundleID: "com.apple.dt.Xcode"),
                WorkspaceApp(bundleID: "com.apple.Safari"),
            ]
        )

        let running: Set<String> = ["com.apple.dt.Xcode", "com.apple.Safari"]
        let suggestions = provider.evaluate(
            workspaces: [workspace],
            runningApps: running,
            activeWorkspaceID: workspace.id
        )

        #expect(suggestions.isEmpty, "Active workspace should not be re-suggested")
    }

    @Test("Confidence scales with completeness")
    func confidenceScalesWithCompleteness() {
        let workspace = Workspace(
            name: "Dev",
            apps: [
                WorkspaceApp(bundleID: "com.app.a"),
                WorkspaceApp(bundleID: "com.app.b"),
                WorkspaceApp(bundleID: "com.app.c"),
                WorkspaceApp(bundleID: "com.app.d"),
            ]
        )

        // 2 of 4 running
        let partial = provider.evaluate(
            workspaces: [workspace],
            runningApps: ["com.app.a", "com.app.b"]
        )

        // 4 of 4 running
        let full = provider.evaluate(
            workspaces: [workspace],
            runningApps: ["com.app.a", "com.app.b", "com.app.c", "com.app.d"]
        )

        #expect(!partial.isEmpty && !full.isEmpty)
        #expect(full[0].confidence > partial[0].confidence,
                "Full workspace (\(full[0].confidence)) should have higher confidence than partial (\(partial[0].confidence))")
    }

    @Test("Multiple workspaces can be suggested")
    func multipleWorkspaces() {
        let ws1 = Workspace(
            name: "Dev",
            apps: [WorkspaceApp(bundleID: "com.app.a"), WorkspaceApp(bundleID: "com.app.b")]
        )
        let ws2 = Workspace(
            name: "Design",
            apps: [WorkspaceApp(bundleID: "com.app.c"), WorkspaceApp(bundleID: "com.app.d")]
        )

        let running: Set<String> = ["com.app.a", "com.app.b", "com.app.c", "com.app.d"]
        let suggestions = provider.evaluate(workspaces: [ws1, ws2], runningApps: running)

        #expect(suggestions.count == 2, "Both workspaces should be suggested")
    }
}

// MARK: - SuggestionKind Tests

@Suite("SuggestionKind")
struct SuggestionKindTests {

    @Test("App suggestion has .app kind by default")
    func appKindDefault() {
        let s = Suggestion(bundleID: "com.test.app", confidence: 0.9, sourcePackID: "test")
        #expect(s.kind == .app)
        #expect(!s.isWorkspace)
        #expect(s.workspaceID == nil)
    }

    @Test("Workspace suggestion has correct kind")
    func workspaceKind() {
        let id = UUID()
        let s = Suggestion(
            bundleID: "workspace:\(id.uuidString)",
            confidence: 0.85,
            sourcePackID: "workspaces",
            kind: .workspace(workspaceID: id)
        )
        #expect(s.isWorkspace)
        #expect(s.workspaceID == id)
    }

    @Test("SuggestionKind.from parses workspace bundleID")
    func parseWorkspaceBundleID() {
        let id = UUID()
        let kind = SuggestionKind.from(bundleID: "workspace:\(id.uuidString)")
        if case .workspace(let parsedID) = kind {
            #expect(parsedID == id)
        } else {
            #expect(Bool(false), "Should parse as workspace")
        }
    }

    @Test("SuggestionKind.from returns .app for regular bundleID")
    func parseRegularBundleID() {
        let kind = SuggestionKind.from(bundleID: "com.apple.Safari")
        #expect(kind == .app)
    }
}
