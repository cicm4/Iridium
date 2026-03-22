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

        Logger.signals.info("SignalCollector started")
        return stream
    }

    func stop() {
        clipboardMonitor.stop()
        appActivityMonitor.stop()
        continuation?.finish()
        continuation = nil
        signalStream = nil
        Logger.signals.info("SignalCollector stopped")
    }

    private func emitSignal(clipboardSnapshot: ClipboardMonitor.ClipboardSnapshot) {
        let signal = ContextSignal(
            clipboardUTI: clipboardSnapshot.uti,
            clipboardSample: clipboardSnapshot.sample,
            frontmostAppBundleID: appActivityMonitor.currentBundleID,
            hourOfDay: timeProvider.currentHourOfDay,
            displayCount: displayProvider.displayCount,
            focusModeActive: focusProvider.isFocusModeActive
        )

        Logger.signals.debug("Signal emitted: UTI=\(signal.clipboardUTI ?? "nil", privacy: .public), app=\(signal.frontmostAppBundleID ?? "nil", privacy: .public)")
        continuation?.yield(signal)
    }
}
