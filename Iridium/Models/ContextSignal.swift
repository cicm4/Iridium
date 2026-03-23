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

    // Phase 3: Enhanced signal fields (all optional, nil = not collected)
    let windowTitle: String?
    let screenContentSample: String?
    let activeFileExtensions: [String]?
    let upcomingMeetingInMinutes: Int?
    let browserDomain: String?
    let browserTabTitle: String?
    let clipboardPatternHint: String?

    // Phase 5: Integration signals (namespace.key → value)
    let integrationSignals: [String: String]?

    init(
        clipboardUTI: String? = nil,
        clipboardSample: String? = nil,
        contentType: ContentType? = nil,
        language: ProgrammingLanguage? = nil,
        frontmostAppBundleID: String? = nil,
        hourOfDay: Int = Calendar.current.component(.hour, from: Date()),
        displayCount: Int = 1,
        focusModeActive: Bool = false,
        timestamp: ContinuousClock.Instant = .now,
        windowTitle: String? = nil,
        screenContentSample: String? = nil,
        activeFileExtensions: [String]? = nil,
        upcomingMeetingInMinutes: Int? = nil,
        browserDomain: String? = nil,
        browserTabTitle: String? = nil,
        clipboardPatternHint: String? = nil,
        integrationSignals: [String: String]? = nil
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
        self.windowTitle = windowTitle
        self.screenContentSample = screenContentSample
        self.activeFileExtensions = activeFileExtensions
        self.upcomingMeetingInMinutes = upcomingMeetingInMinutes
        self.browserDomain = browserDomain
        self.browserTabTitle = browserTabTitle
        self.clipboardPatternHint = clipboardPatternHint
        self.integrationSignals = integrationSignals
    }

    /// Maximum bytes read from clipboard content for classification.
    static let maxSampleBytes = 512
}
