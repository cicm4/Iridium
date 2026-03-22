//
//  ClipboardMonitor.swift
//  Iridium
//

import AppKit
import OSLog

protocol PasteboardProviding: Sendable {
    var changeCount: Int { get }
    func string(forType dataType: NSPasteboard.PasteboardType) -> String?
    func types() -> [NSPasteboard.PasteboardType]?
}

extension NSPasteboard: @retroactive @unchecked Sendable {}
extension NSPasteboard: PasteboardProviding {
    func types() -> [NSPasteboard.PasteboardType]? {
        self.types
    }
}

@MainActor
final class ClipboardMonitor: SignalProvider {
    struct ClipboardSnapshot: Sendable {
        let uti: String?
        let sample: String?
    }

    private var timer: Timer?
    private var lastChangeCount: Int
    private let pasteboard: any PasteboardProviding
    private let pollInterval: TimeInterval
    private var onChange: ((ClipboardSnapshot) -> Void)?

    nonisolated init(
        pasteboard: any PasteboardProviding = NSPasteboard.general,
        pollInterval: TimeInterval = 0.25
    ) {
        self.pasteboard = pasteboard
        self.pollInterval = pollInterval
        self.lastChangeCount = pasteboard.changeCount
    }

    func onClipboardChange(_ handler: @escaping (ClipboardSnapshot) -> Void) {
        self.onChange = handler
    }

    func start() {
        stop()
        lastChangeCount = pasteboard.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.checkForChanges()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkForChanges() {
        let currentCount = pasteboard.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        let uti = pasteboard.types()?.first?.rawValue
        let sample: String? = {
            guard let text = pasteboard.string(forType: .string) else { return nil }
            if text.count <= ContextSignal.maxSampleBytes {
                return text
            }
            return String(text.prefix(ContextSignal.maxSampleBytes))
        }()

        Logger.signals.debug("Clipboard changed: UTI=\(uti ?? "nil", privacy: .public)")
        onChange?(ClipboardSnapshot(uti: uti, sample: sample))
    }
}
