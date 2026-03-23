//
//  WorkspaceSuggestionProvider.swift
//  Iridium
//
//  Evaluates workspaces against the current context to produce workspace suggestions.
//  A workspace is suggested if 2+ of its apps are currently running.
//

import Foundation
import OSLog

struct WorkspaceSuggestionProvider: Sendable {
    /// Minimum apps from a workspace that must be running to suggest it.
    static let minimumRunningApps = 2

    /// Base confidence for workspace suggestions.
    static let baseConfidence: Double = 0.80

    /// Evaluates all workspaces and returns suggestions for relevant ones.
    func evaluate(
        workspaces: [Workspace],
        runningApps: Set<String>,
        activeWorkspaceID: UUID? = nil
    ) -> [Suggestion] {
        var suggestions: [Suggestion] = []

        for workspace in workspaces {
            // Don't re-suggest the already active workspace
            if workspace.id == activeWorkspaceID { continue }

            let runningCount = workspace.runningCount(in: runningApps)

            guard runningCount >= Self.minimumRunningApps else { continue }

            // Confidence scales with how many of the workspace's apps are running
            let completeness = Double(runningCount) / Double(workspace.apps.count)
            let confidence = Self.baseConfidence + completeness * 0.15

            suggestions.append(Suggestion(
                bundleID: "workspace:\(workspace.id.uuidString)",
                confidence: min(confidence, 1.0),
                sourcePackID: "com.iridium.workspaces"
            ))
        }

        Logger.windowManager.debug("Workspace evaluation: \(suggestions.count) suggestions from \(workspaces.count) workspaces")
        return suggestions
    }
}
