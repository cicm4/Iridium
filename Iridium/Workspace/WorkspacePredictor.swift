//
//  WorkspacePredictor.swift
//  Iridium
//
//  Predicts which app the user most likely needs next based on screen context.
//  Uses weighted multi-signal scoring with learned preferences.
//

import Foundation
import OSLog

struct PredictionReason: Sendable, Equatable {
    let shortText: String
}

@MainActor
final class WorkspacePredictor {
    private let workspaceLearner: WorkspaceLearner
    private let installedAppRegistry: InstalledAppRegistry
    private let interactionTracker: InteractionTracker?
    private let adaptiveWeightStore: AdaptiveWeightStore?

    /// Scoring weights — must sum to 1.0
    static let weightCoOccurrence: Double = 0.30
    static let weightTaskAffinity: Double = 0.20
    static let weightRunning: Double = 0.15
    static let weightRecency: Double = 0.15
    static let weightTemporal: Double = 0.10
    static let weightInteraction: Double = 0.10

    /// Maximum candidates from non-running apps
    static let maxNonRunningCandidates = 10

    /// Source pack ID for workspace predictions
    static let sourcePackID = "com.iridium.predictor"

    init(
        workspaceLearner: WorkspaceLearner,
        installedAppRegistry: InstalledAppRegistry,
        interactionTracker: InteractionTracker? = nil,
        adaptiveWeightStore: AdaptiveWeightStore? = nil
    ) {
        self.workspaceLearner = workspaceLearner
        self.installedAppRegistry = installedAppRegistry
        self.interactionTracker = interactionTracker
        self.adaptiveWeightStore = adaptiveWeightStore
    }

    func predict(context: ScreenContext) -> [Suggestion] {
        let frontmostBundleID = context.frontmostBundleID ?? ""

        // Gather candidates
        var candidates: Set<String> = []

        // Pool 1: All running background apps
        for app in context.runningApps where !app.isActive {
            candidates.insert(app.bundleID)
        }

        // Pool 2: Predicted non-running apps (high co-occurrence or task affinity)
        let nonRunningCandidates = gatherNonRunningCandidates(
            frontmostBundleID: frontmostBundleID,
            context: context,
            excluding: candidates
        )
        candidates.formUnion(nonRunningCandidates)

        // Score each candidate
        var scored: [(bundleID: String, score: Double, reason: PredictionReason)] = []

        for candidateBundleID in candidates {
            let (score, reason) = scoreCandidate(
                candidateBundleID,
                frontmostBundleID: frontmostBundleID,
                context: context
            )
            if score > 0.05 {
                scored.append((candidateBundleID, score, reason))
            }
        }

        // Sort by score descending, take top 5
        scored.sort { $0.score > $1.score }
        let top = scored.prefix(SuggestionResult.maxSuggestions)

        return top.map { entry in
            Suggestion(
                bundleID: entry.bundleID,
                confidence: min(entry.score, 1.0),
                sourcePackID: Self.sourcePackID,
                contextHint: entry.reason.shortText
            )
        }
    }

    // MARK: - Private

    private func gatherNonRunningCandidates(
        frontmostBundleID: String,
        context: ScreenContext,
        excluding existing: Set<String>
    ) -> Set<String> {
        var candidates: Set<String> = []

        // Apps with high co-occurrence with frontmost
        if let neighbors = workspaceLearner.coOccurrences[frontmostBundleID] {
            let maxCount = neighbors.values.max() ?? 1
            for (bundleID, count) in neighbors {
                let normalized = Double(count) / Double(max(maxCount, 1))
                if normalized > 0.3 && !existing.contains(bundleID) {
                    candidates.insert(bundleID)
                }
            }
        }

        // Apps with high task affinity
        if let taskCategories = context.activeTaskCategories {
            let highAffinityCategories = taskCategories.filter { $0.value > 0.6 }.map(\.key)
            for category in highAffinityCategories {
                for (bundleID, info) in installedAppRegistry.apps {
                    if info.category == category && !existing.contains(bundleID) {
                        candidates.insert(bundleID)
                    }
                }
            }
        }

        // Top temporal apps for this hour
        let hour = context.hourOfDay
        let hourlyApps = workspaceLearner.hourlyUsage.compactMap { (bundleID, hours) -> (String, Int)? in
            guard let count = hours[hour], count > 0 else { return nil }
            return (bundleID, count)
        }
        .sorted { $0.1 > $1.1 }
        .prefix(5)

        for (bundleID, _) in hourlyApps {
            if !existing.contains(bundleID) {
                candidates.insert(bundleID)
            }
        }

        // Filter to installed apps only and cap
        let installed = candidates.filter { installedAppRegistry.isInstalled($0) }
        return Set(installed.prefix(Self.maxNonRunningCandidates))
    }

    private func scoreCandidate(
        _ candidateBundleID: String,
        frontmostBundleID: String,
        context: ScreenContext
    ) -> (Double, PredictionReason) {
        var factors: [(name: String, weight: Double, score: Double)] = []

        // 1. Co-occurrence score
        let coOccurrence = coOccurrenceScore(candidate: candidateBundleID, frontmost: frontmostBundleID)
        factors.append(("coOccurrence", Self.weightCoOccurrence, coOccurrence))

        // 2. Task affinity
        let taskAffinity = taskAffinityScore(candidate: candidateBundleID, context: context)
        factors.append(("taskAffinity", Self.weightTaskAffinity, taskAffinity))

        // 3. Running bonus
        let isRunning = context.runningApps.contains { $0.bundleID == candidateBundleID && !$0.isActive }
        let running = isRunning ? 1.0 : 0.0
        factors.append(("running", Self.weightRunning, running))

        // 4. Recency
        let recency = recencyScore(candidate: candidateBundleID)
        factors.append(("recency", Self.weightRecency, recency))

        // 5. Temporal
        let temporal = temporalScore(candidate: candidateBundleID, hour: context.hourOfDay)
        factors.append(("temporal", Self.weightTemporal, temporal))

        // 6. Interaction history
        let interaction = interactionScore(candidate: candidateBundleID)
        factors.append(("interaction", Self.weightInteraction, interaction))

        // Weighted sum
        let totalScore = factors.reduce(0.0) { $0 + $1.weight * $1.score }

        // Determine dominant factor for context hint
        let dominantFactor = factors.max { ($0.weight * $0.score) < ($1.weight * $1.score) }
        let reason = contextHint(
            for: dominantFactor?.name ?? "running",
            candidateBundleID: candidateBundleID,
            frontmostBundleID: frontmostBundleID,
            context: context
        )

        return (totalScore, reason)
    }

    private func coOccurrenceScore(candidate: String, frontmost: String) -> Double {
        guard let neighbors = workspaceLearner.coOccurrences[frontmost] else { return 0.0 }
        let maxCount = neighbors.values.max() ?? 1
        let count = neighbors[candidate] ?? 0
        return Double(count) / Double(max(maxCount, 1))
    }

    private func taskAffinityScore(candidate: String, context: ScreenContext) -> Double {
        guard let taskCategories = context.activeTaskCategories else { return 0.5 }
        let candidateCategory = installedAppRegistry.category(for: candidate)
        return taskCategories[candidateCategory] ?? 0.0
    }

    private func recencyScore(candidate: String) -> Double {
        guard let lastSwitch = workspaceLearner.lastSwitchTime(bundleID: candidate) else { return 0.0 }
        let elapsed = Date().timeIntervalSince(lastSwitch)
        // Exponential decay with 30-minute half-life
        return exp(-elapsed / 1800.0)
    }

    private func temporalScore(candidate: String, hour: Int) -> Double {
        return workspaceLearner.hourlyFrequency(bundleID: candidate, hour: hour)
    }

    private func interactionScore(candidate: String) -> Double {
        guard let tracker = interactionTracker else { return 0.0 }
        // Scale to 0-1 range (InteractionTracker.maxAdaptiveBoost is 0.15)
        return min(tracker.boostForBundleID(candidate) / 0.15, 1.0)
    }

    private func contextHint(
        for factorName: String,
        candidateBundleID: String,
        frontmostBundleID: String,
        context: ScreenContext
    ) -> PredictionReason {
        let frontmostName = installedAppRegistry.name(for: frontmostBundleID) ?? frontmostBundleID

        switch factorName {
        case "coOccurrence":
            return PredictionReason(shortText: "Often used with \(frontmostName)")
        case "taskAffinity":
            if let taskName = context.activeTaskName {
                return PredictionReason(shortText: "Matches task: \(taskName)")
            }
            return PredictionReason(shortText: "Fits your current task")
        case "running":
            return PredictionReason(shortText: "Already running")
        case "recency":
            return PredictionReason(shortText: "Recently used")
        case "temporal":
            return PredictionReason(shortText: "You usually open this around now")
        case "interaction":
            return PredictionReason(shortText: "Frequently selected")
        default:
            return PredictionReason(shortText: "Suggested")
        }
    }
}
