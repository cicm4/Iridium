//
//  SignalCollector.swift
//  Iridium
//

import AppKit
import OSLog

@MainActor
final class SignalCollector {
    private let clipboardMonitor: ClipboardMonitor
    private let appActivityMonitor: AppActivityMonitor
    private let timeProvider: TimeSignalProvider
    private let displayProvider: DisplaySignalProvider
    private let focusProvider: any FocusModeProviding

    // Phase 3: Enhanced signal providers (optional, opt-in)
    private var browserTabProvider: BrowserTabProvider?
    private var calendarProvider: CalendarSignalProvider?
    private var clipboardHistoryProvider: ClipboardHistoryProvider?

    private var continuation: AsyncStream<ContextSignal>.Continuation?
    private(set) var signalStream: AsyncStream<ContextSignal>?

    init(
        clipboardMonitor: ClipboardMonitor = ClipboardMonitor(),
        appActivityMonitor: AppActivityMonitor = AppActivityMonitor(),
        timeProvider: TimeSignalProvider = TimeSignalProvider(),
        displayProvider: DisplaySignalProvider = DisplaySignalProvider(),
        focusProvider: any FocusModeProviding = FocusModeProvider()
    ) {
        self.clipboardMonitor = clipboardMonitor
        self.appActivityMonitor = appActivityMonitor
        self.timeProvider = timeProvider
        self.displayProvider = displayProvider
        self.focusProvider = focusProvider
    }

    /// Configures optional Phase 3 signal providers based on user settings.
    func configureEnhancedProviders(
        enableBrowserTabAnalysis: Bool = false,
        enableCalendarIntegration: Bool = false,
        enableClipboardHistory: Bool = false
    ) {
        browserTabProvider = enableBrowserTabAnalysis ? BrowserTabProvider() : nil
        calendarProvider = enableCalendarIntegration ? CalendarSignalProvider() : nil
        clipboardHistoryProvider = enableClipboardHistory ? ClipboardHistoryProvider() : nil
    }

    func start() -> AsyncStream<ContextSignal> {
        let stream = AsyncStream<ContextSignal> { continuation in
            self.continuation = continuation
        }
        self.signalStream = stream

        clipboardMonitor.onClipboardChange { [weak self] snapshot in
            self?.emitSignal(clipboardSnapshot: snapshot)
        }

        clipboardMonitor.start()
        appActivityMonitor.start()

        // Start optional providers
        browserTabProvider?.start()
        calendarProvider?.start()

        Logger.signals.info("SignalCollector started")
        return stream
    }

    func stop() {
        clipboardMonitor.stop()
        appActivityMonitor.stop()
        browserTabProvider?.stop()
        calendarProvider?.stop()
        clipboardHistoryProvider?.clear()
        continuation?.finish()
        continuation = nil
        signalStream = nil
        Logger.signals.info("SignalCollector stopped")
    }

    private func emitSignal(clipboardSnapshot: ClipboardMonitor.ClipboardSnapshot) {
        // Update browser tab if applicable
        browserTabProvider?.update()

        let signal = ContextSignal(
            clipboardUTI: clipboardSnapshot.uti,
            clipboardSample: clipboardSnapshot.sample,
            frontmostAppBundleID: appActivityMonitor.currentBundleID,
            hourOfDay: timeProvider.currentHourOfDay,
            displayCount: displayProvider.displayCount,
            focusModeActive: focusProvider.isFocusModeActive,
            // Phase 3: Enhanced signals
            upcomingMeetingInMinutes: calendarProvider?.currentContext?.upcomingMeetingInMinutes,
            browserDomain: browserTabProvider?.currentSnapshot?.domain,
            browserTabTitle: browserTabProvider?.currentSnapshot?.title,
            clipboardPatternHint: clipboardHistoryProvider?.patternHint
        )

        // Record in clipboard history for pattern detection
        // (contentType will be enriched later, use nil for now — pattern detection
        // uses source app which is available immediately)
        clipboardHistoryProvider?.record(
            contentType: .unknown,
            sourceApp: appActivityMonitor.currentBundleID
        )

        Logger.signals.debug("Signal emitted: UTI=\(signal.clipboardUTI ?? "nil", privacy: .public), app=\(signal.frontmostAppBundleID ?? "nil", privacy: .public)")
        continuation?.yield(signal)
    }

    /// Updates clipboard history with the actual content type after classification.
    /// Called by PredictionEngine after classification completes.
    func updateClipboardHistory(contentType: ContentType, sourceApp: String?) {
        // Replace the last entry's unknown type with the actual type
        clipboardHistoryProvider?.record(contentType: contentType, sourceApp: sourceApp)
    }
}
