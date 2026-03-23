//
//  ClipboardHistoryProvider.swift
//  Iridium
//
//  Maintains a ring buffer of recent clipboard entries and detects patterns:
//  - 3+ URLs in a row → "research"
//  - Alternating between 2 apps → "comparison"
//  - 3+ code snippets → "development"
//  - Mixed content → nil (no pattern)
//

import Foundation
import OSLog

final class ClipboardHistoryProvider: @unchecked Sendable {
    struct ClipboardEntry: Sendable {
        let contentType: ContentType
        let sourceApp: String?
        let timestamp: ContinuousClock.Instant
    }

    /// Maximum entries in the ring buffer.
    static let bufferSize = 10

    private var buffer: [ClipboardEntry] = []
    private let lock = NSLock()

    /// The detected clipboard pattern, if any.
    var patternHint: String? {
        lock.lock()
        defer { lock.unlock() }
        return detectPattern()
    }

    /// Records a new clipboard entry.
    func record(contentType: ContentType, sourceApp: String?) {
        lock.lock()
        defer { lock.unlock() }

        buffer.append(ClipboardEntry(
            contentType: contentType,
            sourceApp: sourceApp,
            timestamp: .now
        ))

        // Trim to buffer size
        if buffer.count > Self.bufferSize {
            buffer.removeFirst(buffer.count - Self.bufferSize)
        }
    }

    /// Clears the history.
    func clear() {
        lock.lock()
        defer { lock.unlock() }
        buffer.removeAll()
    }

    /// Number of entries currently in the buffer.
    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return buffer.count
    }

    // MARK: - Pattern Detection

    private func detectPattern() -> String? {
        guard buffer.count >= 3 else { return nil }

        let recent = Array(buffer.suffix(5))

        // Check for URL research pattern (3+ URLs)
        let urlCount = recent.filter { $0.contentType == .url }.count
        if urlCount >= 3 {
            return "research"
        }

        // Check for code development pattern (3+ code snippets)
        let codeCount = recent.filter { $0.contentType == .code }.count
        if codeCount >= 3 {
            return "development"
        }

        // Check for comparison pattern (alternating between 2 apps)
        let recentApps = recent.compactMap(\.sourceApp)
        if recentApps.count >= 4 {
            let uniqueApps = Set(recentApps)
            if uniqueApps.count == 2 {
                // Check if they actually alternate
                var alternating = true
                for i in 1..<recentApps.count {
                    if recentApps[i] == recentApps[i - 1] {
                        alternating = false
                        break
                    }
                }
                if alternating {
                    return "comparison"
                }
            }
        }

        // Check for writing pattern (3+ prose)
        let proseCount = recent.filter { $0.contentType == .prose }.count
        if proseCount >= 3 {
            return "writing"
        }

        return nil
    }
}
