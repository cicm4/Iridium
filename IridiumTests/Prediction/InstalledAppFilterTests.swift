//
//  InstalledAppFilterTests.swift
//  IridiumTests
//

import AppKit
import Testing
@testable import Iridium

@MainActor
struct InstalledAppFilterTests {
    @Test func safariIsAlwaysInstalled() {
        // com.apple.Safari is always present on macOS
        let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Safari")
        #expect(url != nil)
    }

    @Test func fakeAppIsNotInstalled() {
        let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.fake.nonexistent.app12345")
        #expect(url == nil)
    }

    @Test func filterRemovesUninstalledApps() {
        let suggestions = [
            Suggestion(bundleID: "com.apple.Safari", confidence: 0.90, sourcePackID: "test"),
            Suggestion(bundleID: "com.fake.nonexistent.app12345", confidence: 0.95, sourcePackID: "test"),
        ]

        let filtered = suggestions.filter { suggestion in
            NSWorkspace.shared.urlForApplication(withBundleIdentifier: suggestion.bundleID) != nil
        }

        #expect(filtered.count == 1)
        #expect(filtered[0].bundleID == "com.apple.Safari")
    }

    @Test func filterPreservesOrder() {
        let suggestions = [
            Suggestion(bundleID: "com.apple.Safari", confidence: 0.95, sourcePackID: "test"),
            Suggestion(bundleID: "com.apple.mail", confidence: 0.90, sourcePackID: "test"),
            Suggestion(bundleID: "com.fake.nonexistent", confidence: 0.85, sourcePackID: "test"),
            Suggestion(bundleID: "com.apple.Notes", confidence: 0.80, sourcePackID: "test"),
        ]

        let filtered = suggestions.filter { suggestion in
            NSWorkspace.shared.urlForApplication(withBundleIdentifier: suggestion.bundleID) != nil
        }

        // Order preserved, fake app removed
        #expect(filtered.count == 3)
        #expect(filtered[0].bundleID == "com.apple.Safari")
        #expect(filtered[1].bundleID == "com.apple.mail")
        #expect(filtered[2].bundleID == "com.apple.Notes")
    }
}
