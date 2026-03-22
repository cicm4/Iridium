//
//  SignalFusion.swift
//  Iridium
//

import Foundation

struct SignalFusion: Sendable {
    /// Enriches a ContextSignal with classification results.
    func enrich(
        signal: ContextSignal,
        classification: ClassificationResult
    ) -> ContextSignal {
        ContextSignal(
            clipboardUTI: signal.clipboardUTI,
            clipboardSample: signal.clipboardSample,
            contentType: classification.contentType,
            language: classification.language,
            frontmostAppBundleID: signal.frontmostAppBundleID,
            hourOfDay: signal.hourOfDay,
            displayCount: signal.displayCount,
            focusModeActive: signal.focusModeActive,
            timestamp: signal.timestamp
        )
    }
}
