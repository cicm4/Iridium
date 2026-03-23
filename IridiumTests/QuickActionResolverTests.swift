//
//  QuickActionResolverTests.swift
//  IridiumTests
//

import Testing
import Foundation
@testable import Iridium

@MainActor
struct QuickActionResolverTests {
    let resolver = QuickActionResolver()

    // MARK: - URL Actions

    @Test func urlWithSafariReturnsOpenURLAction() {
        let actions = resolver.resolve(
            bundleID: "com.apple.Safari",
            contentType: .url,
            clipboardText: "https://example.com"
        )
        #expect(actions.count == 1)
        #expect(actions[0].title == "Open URL")
        #expect(actions[0].icon == "globe")
    }

    @Test func urlWithChromeReturnsOpenURLAction() {
        let actions = resolver.resolve(
            bundleID: "com.google.Chrome",
            contentType: .url,
            clipboardText: "https://example.com"
        )
        #expect(actions.count == 1)
        #expect(actions[0].title == "Open URL")
    }

    @Test func urlWithNonBrowserReturnsEmpty() {
        let actions = resolver.resolve(
            bundleID: "com.apple.TextEdit",
            contentType: .url,
            clipboardText: "https://example.com"
        )
        #expect(actions.isEmpty)
    }

    // MARK: - File Actions

    @Test func fileWithFinderReturnsRevealAction() {
        let actions = resolver.resolve(
            bundleID: "com.apple.finder",
            contentType: .file,
            clipboardText: "/Users/test/document.pdf"
        )
        #expect(actions.count == 1)
        #expect(actions[0].title == "Reveal in Finder")
        #expect(actions[0].icon == "folder")
    }

    @Test func fileWithOtherAppReturnsOpenFileAction() {
        let actions = resolver.resolve(
            bundleID: "com.apple.Preview",
            contentType: .file,
            clipboardText: "/Users/test/image.png"
        )
        #expect(actions.count == 1)
        #expect(actions[0].title == "Open File")
        #expect(actions[0].icon == "doc")
    }

    // MARK: - Email Actions

    @Test func emailWithMailReturnsComposeAction() {
        let actions = resolver.resolve(
            bundleID: "com.apple.mail",
            contentType: .email,
            clipboardText: "user@example.com"
        )
        #expect(actions.count == 1)
        #expect(actions[0].title == "Compose Email")
        #expect(actions[0].icon == "envelope")
    }

    @Test func emailWithNonMailAppReturnsEmpty() {
        let actions = resolver.resolve(
            bundleID: "com.apple.Safari",
            contentType: .email,
            clipboardText: "user@example.com"
        )
        #expect(actions.isEmpty)
    }

    // MARK: - Edge Cases

    @Test func emptyClipboardReturnsEmpty() {
        let actions = resolver.resolve(
            bundleID: "com.apple.Safari",
            contentType: .url,
            clipboardText: nil
        )
        #expect(actions.isEmpty)
    }

    @Test func blankClipboardReturnsEmpty() {
        let actions = resolver.resolve(
            bundleID: "com.apple.Safari",
            contentType: .url,
            clipboardText: ""
        )
        #expect(actions.isEmpty)
    }

    @Test func codeContentReturnsEmpty() {
        let actions = resolver.resolve(
            bundleID: "com.apple.dt.Xcode",
            contentType: .code,
            clipboardText: "let x = 42"
        )
        #expect(actions.isEmpty)
    }

    @Test func proseContentReturnsEmpty() {
        let actions = resolver.resolve(
            bundleID: "com.apple.TextEdit",
            contentType: .prose,
            clipboardText: "Hello world"
        )
        #expect(actions.isEmpty)
    }

    // MARK: - Browser Bundle IDs

    @Test func allKnownBrowsersAreRecognized() {
        for browserID in QuickActionResolver.browserBundleIDs {
            let actions = resolver.resolve(
                bundleID: browserID,
                contentType: .url,
                clipboardText: "https://example.com"
            )
            #expect(!actions.isEmpty, "Browser \(browserID) should produce URL action")
        }
    }
}
