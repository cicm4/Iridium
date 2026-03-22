//
//  PredictionEngine.swift
//  Iridium
//

import Foundation
import OSLog

@MainActor
final class PredictionEngine {
    private let classificationPipeline: ClassificationPipeline
    private let packEvaluator = PackEvaluator()
    private let signalFusion = SignalFusion()
    private let ranker = SuggestionRanker()
    let interactionTracker = InteractionTracker()

    private var packRegistry: PackRegistry?
    private var settings: SettingsStore?

    private var resultContinuation: AsyncStream<SuggestionResult>.Continuation?
    private(set) var resultStream: AsyncStream<SuggestionResult>?

    init() {
        self.classificationPipeline = ClassificationPipeline()
    }

    func configure(packRegistry: PackRegistry, settings: SettingsStore) {
        self.packRegistry = packRegistry
        self.settings = settings
    }

    func start() -> AsyncStream<SuggestionResult> {
        let stream = AsyncStream<SuggestionResult> { continuation in
            self.resultContinuation = continuation
        }
        self.resultStream = stream
        return stream
    }

    func stop() {
        resultContinuation?.finish()
        resultContinuation = nil
        resultStream = nil
        interactionTracker.reset()
    }

    func processSignal(_ signal: ContextSignal) async {
        guard let settings, settings.isEnabled, settings.showSuggestions else { return }

        // Respect Focus Mode
        if settings.respectFocusMode && signal.focusModeActive { return }

        // Frequency capping
        if interactionTracker.isSuppressed { return }

        // Update Foundation Models setting
        await classificationPipeline.setFoundationModelsEnabled(settings.enableFoundationModels)

        // Run tiered classification
        let classification = await classificationPipeline.classify(
            uti: signal.clipboardUTI,
            sample: signal.clipboardSample
        )

        // Enrich signal with classification
        let enrichedSignal = signalFusion.enrich(signal: signal, classification: classification)

        // Evaluate packs
        guard let packRegistry else { return }
        let suggestions = packEvaluator.evaluate(
            signal: enrichedSignal,
            packs: packRegistry.enabledPacks
        )

        guard !suggestions.isEmpty else {
            Logger.prediction.debug("No suggestions from packs")
            return
        }

        // Rank and deduplicate
        let ranked = ranker.rank(
            suggestions: suggestions,
            signalTimestamp: signal.timestamp,
            interactionTracker: interactionTracker
        )

        // Filter by confidence threshold
        let filtered = ranked.filter { $0.confidence >= settings.confidenceThreshold }
        guard !filtered.isEmpty else { return }

        let result = SuggestionResult(suggestions: filtered, signal: enrichedSignal)
        resultContinuation?.yield(result)
        Logger.prediction.info("Prediction complete: \(filtered.count) suggestions")
    }
}
