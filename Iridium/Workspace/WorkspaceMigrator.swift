//
//  WorkspaceMigrator.swift
//  Iridium
//
//  One-time migration from preset-based workspaces to learned data.
//

import Foundation
import OSLog

struct WorkspaceMigrator {
    /// Migrates old workspace presets into the learning system.
    /// Seeds co-occurrences with threshold count so learned pairs have an immediate head start.
    func migrate(from workspaces: [Workspace], into learner: WorkspaceLearner) {
        guard !workspaces.isEmpty else { return }

        for workspace in workspaces {
            let bundleIDs = workspace.apps.map(\.bundleID)
            guard bundleIDs.count >= 2 else { continue }

            // Seed co-occurrences: inject threshold count for each pair
            for i in 0..<bundleIDs.count {
                for j in (i + 1)..<bundleIDs.count {
                    for _ in 0..<WorkspaceLearner.suggestionThreshold {
                        let set: Set<String> = [bundleIDs[i], bundleIDs[j]]
                        learner.recordCoActivation(runningApps: set)
                    }
                }
            }

            // Seed layout preferences from workspace app regions
            for i in 0..<workspace.apps.count {
                for j in (i + 1)..<workspace.apps.count {
                    let appA = workspace.apps[i]
                    let appB = workspace.apps[j]
                    // Record 3 times to meet the learned threshold
                    for _ in 0..<3 {
                        learner.recordLayoutChoice(
                            appA: appA.bundleID,
                            regionA: appA.region,
                            appB: appB.bundleID,
                            regionB: appB.region
                        )
                    }
                }
            }

            Logger.learning.info("Migrated workspace '\(workspace.name)' with \(bundleIDs.count) apps")
        }
    }
}
