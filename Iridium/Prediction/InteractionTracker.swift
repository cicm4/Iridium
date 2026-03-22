//
//  InteractionTracker.swift
//  Iridium
//

import Foundation
import OSLog

@Observable
final class InteractionTracker {
    /// In-memory counts of how often each bundle ID was selected.
    /// Resets on app quit. Never persisted unless user enables persistent learning.
    private(set) var selectionCounts: [String: Int] = [:]

    /// Consecutive dismissals without selection (for frequency capping).
    private(set) var consecutiveDismissals = 0

    /// Whether suggestions should be suppressed due to repeated dismissals.
    var isSuppressed: Bool {
        consecutiveDismissals >= 3
    }

    private var suppressionTimer: Task<Void, Never>?

    func recordSelection(bundleID: String) {
        selectionCounts[bundleID, default: 0] += 1
        consecutiveDismissals = 0
        suppressionTimer?.cancel()
        Logger.prediction.debug("Recorded selection: \(bundleID) (total: \(self.selectionCounts[bundleID] ?? 0))")
    }

    func recordDismissal() {
        consecutiveDismissals += 1
        Logger.prediction.debug("Recorded dismissal (\(self.consecutiveDismissals) consecutive)")

        if isSuppressed {
            // Auto-unsuppress after 5 minutes
            suppressionTimer?.cancel()
            suppressionTimer = Task { @MainActor in
                try? await Task.sleep(for: .seconds(300))
                guard !Task.isCancelled else { return }
                self.consecutiveDismissals = 0
                Logger.prediction.debug("Suppression lifted after 5 minutes")
            }
        }
    }

    /// Returns a confidence boost for a bundle ID based on interaction history.
    /// Range: 0.0 (never selected) to 0.15 (frequently selected).
    func boostForBundleID(_ bundleID: String) -> Double {
        guard let count = selectionCounts[bundleID], count > 0 else { return 0.0 }
        // Logarithmic scaling: diminishing returns after many selections
        return min(0.15, log(Double(count + 1)) / log(50.0) * 0.15)
    }

    func reset() {
        selectionCounts.removeAll()
        consecutiveDismissals = 0
        suppressionTimer?.cancel()
    }
}
