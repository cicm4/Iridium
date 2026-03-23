//
//  EnhancedSignalTests.swift
//  IridiumTests
//
//  Integration tests verifying Phase 3 enhanced signals flow through
//  the full pipeline: ContextSignal → TriggerMatcher → PackEvaluator.
//

import Testing
@testable import Iridium

@Suite("Enhanced Signal Pipeline")
struct EnhancedSignalTests {

    // MARK: - TriggerMatcher new signal resolution

    @Test("TriggerMatcher resolves browser.domain")
    func triggerMatchesBrowserDomain() {
        let matcher = TriggerMatcher()
        let signal = ContextSignal(browserDomain: "github.com")
        let trigger = PackManifest.Trigger(
            signal: "browser.domain",
            matches: .exact("github.com"),
            conditions: nil,
            confidence: 0.85,
            suggest: ["com.microsoft.VSCode"]
        )
        #expect(matcher.matches(trigger, signal: signal))
    }

    @Test("TriggerMatcher resolves browser.domain with anyOf")
    func triggerMatchesBrowserDomainAnyOf() {
        let matcher = TriggerMatcher()
        let signal = ContextSignal(browserDomain: "gitlab.com")
        let trigger = PackManifest.Trigger(
            signal: "browser.domain",
            matches: .anyOf(["github.com", "gitlab.com", "bitbucket.org"]),
            conditions: nil,
            confidence: 0.85,
            suggest: ["com.microsoft.VSCode"]
        )
        #expect(matcher.matches(trigger, signal: signal))
    }

    @Test("TriggerMatcher resolves calendar.meetingSoon with range")
    func triggerMatchesCalendarRange() {
        let matcher = TriggerMatcher()
        let signal = ContextSignal(upcomingMeetingInMinutes: 3)
        let trigger = PackManifest.Trigger(
            signal: "calendar.meetingSoon",
            matches: .range(gte: 0, lte: 5),
            conditions: nil,
            confidence: 0.90,
            suggest: ["us.zoom.xos"]
        )
        #expect(matcher.matches(trigger, signal: signal))
    }

    @Test("TriggerMatcher does not match calendar when no meeting")
    func triggerNoMatchWithoutMeeting() {
        let matcher = TriggerMatcher()
        let signal = ContextSignal()  // No meeting data
        let trigger = PackManifest.Trigger(
            signal: "calendar.meetingSoon",
            matches: .range(gte: 0, lte: 5),
            conditions: nil,
            confidence: 0.90,
            suggest: ["us.zoom.xos"]
        )
        #expect(!matcher.matches(trigger, signal: signal))
    }

    @Test("TriggerMatcher resolves clipboard.pattern")
    func triggerMatchesClipboardPattern() {
        let matcher = TriggerMatcher()
        let signal = ContextSignal(clipboardPatternHint: "research")
        let trigger = PackManifest.Trigger(
            signal: "clipboard.pattern",
            matches: .exact("research"),
            conditions: nil,
            confidence: 0.75,
            suggest: ["com.apple.Notes"]
        )
        #expect(matcher.matches(trigger, signal: signal))
    }

    @Test("TriggerMatcher resolves window.title")
    func triggerMatchesWindowTitle() {
        let matcher = TriggerMatcher()
        let signal = ContextSignal(windowTitle: "MyProject — Xcode")
        let trigger = PackManifest.Trigger(
            signal: "window.title",
            matches: .exact("MyProject — Xcode"),
            conditions: nil,
            confidence: 0.80,
            suggest: ["com.apple.dt.Xcode"]
        )
        #expect(matcher.matches(trigger, signal: signal))
    }

    // MARK: - Full pack evaluation with enhanced signals

    @Test("Browser context pack fires for GitHub domain")
    func browserContextPackFiresForGitHub() {
        let evaluator = PackEvaluator()
        let loader = PackLoader()
        let allPacks = loader.loadBuiltInPacks()

        let browserContextPack = allPacks.first { $0.id == "com.iridium.browser-context" }
        guard let pack = browserContextPack else {
            #expect(Bool(false), "browser-context pack not found in built-in packs")
            return
        }

        let signal = ContextSignal(
            contentType: .url,
            browserDomain: "github.com"
        )

        let suggestions = evaluator.evaluate(signal: signal, packs: [pack])
        #expect(!suggestions.isEmpty, "GitHub domain should trigger browser context pack")

        let bundleIDs = Set(suggestions.map(\.bundleID))
        let hasIDE = bundleIDs.contains("com.todesktop.230313mzl4w4u92")
            || bundleIDs.contains("com.apple.dt.Xcode")
            || bundleIDs.contains("com.microsoft.VSCode")
        #expect(hasIDE, "GitHub should suggest IDEs. Got: \(bundleIDs)")
    }

    @Test("Calendar aware pack fires when meeting is in 3 minutes")
    func calendarAwarePackFires() {
        let evaluator = PackEvaluator()
        let loader = PackLoader()
        let allPacks = loader.loadBuiltInPacks()

        let calendarPack = allPacks.first { $0.id == "com.iridium.calendar-aware" }
        guard let pack = calendarPack else {
            #expect(Bool(false), "calendar-aware pack not found in built-in packs")
            return
        }

        let signal = ContextSignal(upcomingMeetingInMinutes: 3)
        let suggestions = evaluator.evaluate(signal: signal, packs: [pack])

        #expect(!suggestions.isEmpty, "Meeting in 3 min should trigger calendar pack")
        let bundleIDs = Set(suggestions.map(\.bundleID))
        let hasCommunication = bundleIDs.contains("us.zoom.xos")
            || bundleIDs.contains("com.microsoft.teams2")
            || bundleIDs.contains("com.tinyspeck.slackmacgap")
        #expect(hasCommunication, "Upcoming meeting should suggest communication apps. Got: \(bundleIDs)")
    }

    @Test("Clipboard research pattern triggers note-taking suggestions")
    func clipboardResearchPatternTriggers() {
        let evaluator = PackEvaluator()
        let loader = PackLoader()
        let allPacks = loader.loadBuiltInPacks()

        let browserPack = allPacks.first { $0.id == "com.iridium.browser-context" }
        guard let pack = browserPack else {
            #expect(Bool(false), "browser-context pack not found")
            return
        }

        let signal = ContextSignal(clipboardPatternHint: "research")
        let suggestions = evaluator.evaluate(signal: signal, packs: [pack])

        #expect(!suggestions.isEmpty, "Research pattern should trigger suggestions")
    }

    // MARK: - SignalFusion preserves enhanced fields

    @Test("SignalFusion preserves all Phase 3 fields")
    func signalFusionPreservesEnhancedFields() {
        let fusion = SignalFusion()
        let signal = ContextSignal(
            clipboardSample: "test",
            windowTitle: "My Window",
            screenContentSample: "some text",
            activeFileExtensions: [".swift", ".py"],
            upcomingMeetingInMinutes: 5,
            browserDomain: "github.com",
            browserTabTitle: "Pull Requests",
            clipboardPatternHint: "development"
        )

        let classification = ClassificationResult(
            contentType: .code,
            language: .swift,
            confidence: 0.90,
            tier: .ruleBased
        )

        let enriched = fusion.enrich(signal: signal, classification: classification)

        #expect(enriched.contentType == .code)
        #expect(enriched.windowTitle == "My Window")
        #expect(enriched.screenContentSample == "some text")
        #expect(enriched.activeFileExtensions == [".swift", ".py"])
        #expect(enriched.upcomingMeetingInMinutes == 5)
        #expect(enriched.browserDomain == "github.com")
        #expect(enriched.browserTabTitle == "Pull Requests")
        #expect(enriched.clipboardPatternHint == "development")
    }

    // MARK: - PackValidator accepts new signals

    @Test("PackValidator accepts Phase 3 signal names")
    func packValidatorAcceptsNewSignals() {
        let validator = PackValidator()
        let newSignals = ["browser.domain", "browser.tabTitle", "calendar.meetingSoon",
                          "clipboard.pattern", "window.title", "screen.content", "file.extensions"]

        for signalName in newSignals {
            let manifest = PackManifest(
                id: "com.test.pack",
                name: "Test",
                version: "1.0",
                author: "Test",
                description: nil,
                minimumIridiumVersion: nil,
                triggers: [
                    PackManifest.Trigger(
                        signal: signalName,
                        matches: .exact("test"),
                        conditions: nil,
                        confidence: 0.80,
                        suggest: ["com.test.app"]
                    )
                ]
            )
            #expect(throws: Never.self) {
                try validator.validate(manifest)
            }
        }
    }
}
