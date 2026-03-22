//
//  TriggerMatcherTests.swift
//  IridiumTests
//

import Testing
@testable import Iridium

struct TriggerMatcherTests {
    let matcher = TriggerMatcher()

    private func signal(
        contentType: ContentType? = nil,
        language: ProgrammingLanguage? = nil,
        app: String? = nil,
        hour: Int = 14,
        displays: Int = 1
    ) -> ContextSignal {
        ContextSignal(
            contentType: contentType,
            language: language,
            frontmostAppBundleID: app,
            hourOfDay: hour,
            displayCount: displays
        )
    }

    private func trigger(
        signal: String,
        matches: MatchExpression,
        confidence: Double = 0.9
    ) -> PackManifest.Trigger {
        PackManifest.Trigger(
            signal: signal,
            matches: matches,
            conditions: nil,
            confidence: confidence,
            suggest: ["com.test.app"]
        )
    }

    // MARK: - Exact String Matching

    @Test func exactStringMatch() {
        let t = trigger(signal: "clipboard.contentType", matches: .exact("code"))
        #expect(matcher.matches(t, signal: signal(contentType: .code)))
    }

    @Test func exactStringMismatch() {
        let t = trigger(signal: "clipboard.contentType", matches: .exact("url"))
        #expect(!matcher.matches(t, signal: signal(contentType: .code)))
    }

    // MARK: - AnyOf Matching

    @Test func anyOfMatch() {
        let t = trigger(signal: "clipboard.language", matches: .anyOf(["swift", "python"]))
        #expect(matcher.matches(t, signal: signal(contentType: .code, language: .swift)))
    }

    @Test func anyOfMismatch() {
        let t = trigger(signal: "clipboard.language", matches: .anyOf(["swift", "python"]))
        #expect(!matcher.matches(t, signal: signal(contentType: .code, language: .javascript)))
    }

    // MARK: - Range Matching

    @Test func rangeMatchWithinBounds() {
        let t = trigger(signal: "time.hourOfDay", matches: .range(gte: 9, lte: 17))
        #expect(matcher.matches(t, signal: signal(hour: 14)))
    }

    @Test func rangeMatchAtLowerBound() {
        let t = trigger(signal: "time.hourOfDay", matches: .range(gte: 9, lte: 17))
        #expect(matcher.matches(t, signal: signal(hour: 9)))
    }

    @Test func rangeMatchAtUpperBound() {
        let t = trigger(signal: "time.hourOfDay", matches: .range(gte: 9, lte: 17))
        #expect(matcher.matches(t, signal: signal(hour: 17)))
    }

    @Test func rangeMatchOutOfBounds() {
        let t = trigger(signal: "time.hourOfDay", matches: .range(gte: 9, lte: 17))
        #expect(!matcher.matches(t, signal: signal(hour: 22)))
    }

    @Test func rangeWithOnlyGte() {
        let t = trigger(signal: "time.hourOfDay", matches: .range(gte: 18, lte: nil))
        #expect(matcher.matches(t, signal: signal(hour: 20)))
        #expect(!matcher.matches(t, signal: signal(hour: 10)))
    }

    @Test func displayCountRange() {
        let t = trigger(signal: "display.count", matches: .range(gte: 2, lte: nil))
        #expect(matcher.matches(t, signal: signal(displays: 3)))
        #expect(!matcher.matches(t, signal: signal(displays: 1)))
    }

    // MARK: - App Frontmost Matching

    @Test func appFrontmostExact() {
        let t = trigger(signal: "app.frontmost", matches: .exact("com.apple.Safari"))
        #expect(matcher.matches(t, signal: signal(app: "com.apple.Safari")))
        #expect(!matcher.matches(t, signal: signal(app: "com.google.Chrome")))
    }

    @Test func appFrontmostAnyOf() {
        let t = trigger(signal: "app.frontmost", matches: .anyOf(["com.apple.Safari", "com.google.Chrome"]))
        #expect(matcher.matches(t, signal: signal(app: "com.apple.Safari")))
        #expect(matcher.matches(t, signal: signal(app: "com.google.Chrome")))
        #expect(!matcher.matches(t, signal: signal(app: "org.mozilla.firefox")))
    }

    // MARK: - Nil Signal Values

    @Test func nilContentTypeDoesNotMatch() {
        let t = trigger(signal: "clipboard.contentType", matches: .exact("code"))
        #expect(!matcher.matches(t, signal: signal(contentType: nil)))
    }

    @Test func nilAppDoesNotMatch() {
        let t = trigger(signal: "app.frontmost", matches: .exact("com.apple.Safari"))
        #expect(!matcher.matches(t, signal: signal(app: nil)))
    }

    // MARK: - Multi-Condition Triggers

    @Test func multiConditionAllMatch() {
        let t = PackManifest.Trigger(
            signal: nil, matches: nil,
            conditions: [
                PackManifest.Condition(signal: "clipboard.contentType", matches: .exact("code")),
                PackManifest.Condition(signal: "clipboard.language", matches: .exact("swift")),
            ],
            confidence: 0.95,
            suggest: ["com.apple.dt.Xcode"]
        )
        #expect(matcher.matches(t, signal: signal(contentType: .code, language: .swift)))
    }

    @Test func multiConditionPartialMatch() {
        let t = PackManifest.Trigger(
            signal: nil, matches: nil,
            conditions: [
                PackManifest.Condition(signal: "clipboard.contentType", matches: .exact("code")),
                PackManifest.Condition(signal: "clipboard.language", matches: .exact("swift")),
            ],
            confidence: 0.95,
            suggest: ["com.apple.dt.Xcode"]
        )
        // Content type matches but language is python, not swift
        #expect(!matcher.matches(t, signal: signal(contentType: .code, language: .python)))
    }

    // MARK: - Exact Number Matching

    @Test func exactNumberForHour() {
        let t = trigger(signal: "time.hourOfDay", matches: .exact("14"))
        #expect(matcher.matches(t, signal: signal(hour: 14)))
        #expect(!matcher.matches(t, signal: signal(hour: 15)))
    }

    @Test func invalidNumberStringDoesNotCrash() {
        let t = trigger(signal: "time.hourOfDay", matches: .exact("not-a-number"))
        // Should return false, not crash
        #expect(!matcher.matches(t, signal: signal(hour: 14)))
    }
}
