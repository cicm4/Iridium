//
//  ContextSignal.swift
//  Iridium
//

import Foundation

struct ContextSignal: Sendable {
    let clipboardUTI: String?
    let clipboardSample: String?
    let contentType: ContentType?
    let language: ProgrammingLanguage?
    let frontmostAppBundleID: String?
    let hourOfDay: Int
    let displayCount: Int
    let focusModeActive: Bool
    let timestamp: ContinuousClock.Instant

    init(
        clipboardUTI: String? = nil,
        clipboardSample: String? = nil,
        contentType: ContentType? = nil,
        language: ProgrammingLanguage? = nil,
        frontmostAppBundleID: String? = nil,
        hourOfDay: Int = Calendar.current.component(.hour, from: Date()),
        displayCount: Int = 1,
        focusModeActive: Bool = false,
        timestamp: ContinuousClock.Instant = .now
    ) {
        self.clipboardUTI = clipboardUTI
        self.clipboardSample = clipboardSample
        self.contentType = contentType
        self.language = language
        self.frontmostAppBundleID = frontmostAppBundleID
        self.hourOfDay = hourOfDay
        self.displayCount = displayCount
        self.focusModeActive = focusModeActive
        self.timestamp = timestamp
    }

    /// Maximum bytes read from clipboard content for classification.
    static let maxSampleBytes = 512
}
