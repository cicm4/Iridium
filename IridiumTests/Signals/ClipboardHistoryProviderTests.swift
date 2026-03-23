//
//  ClipboardHistoryProviderTests.swift
//  IridiumTests
//

import Testing
@testable import Iridium

@Suite("ClipboardHistoryProvider")
struct ClipboardHistoryProviderTests {

    @Test("Empty buffer returns nil pattern")
    func emptyBufferNilPattern() {
        let provider = ClipboardHistoryProvider()
        #expect(provider.patternHint == nil)
    }

    @Test("3+ URLs detected as research pattern")
    func urlResearchPattern() {
        let provider = ClipboardHistoryProvider()
        provider.record(contentType: .url, sourceApp: "com.apple.Safari")
        provider.record(contentType: .url, sourceApp: "com.apple.Safari")
        provider.record(contentType: .url, sourceApp: "com.apple.Safari")

        #expect(provider.patternHint == "research")
    }

    @Test("3+ code snippets detected as development pattern")
    func codeDevelopmentPattern() {
        let provider = ClipboardHistoryProvider()
        provider.record(contentType: .code, sourceApp: "com.microsoft.VSCode")
        provider.record(contentType: .code, sourceApp: "com.microsoft.VSCode")
        provider.record(contentType: .code, sourceApp: "com.microsoft.VSCode")

        #expect(provider.patternHint == "development")
    }

    @Test("Alternating between 2 apps detected as comparison pattern")
    func alternatingComparisonPattern() {
        let provider = ClipboardHistoryProvider()
        provider.record(contentType: .prose, sourceApp: "com.app.a")
        provider.record(contentType: .prose, sourceApp: "com.app.b")
        provider.record(contentType: .prose, sourceApp: "com.app.a")
        provider.record(contentType: .prose, sourceApp: "com.app.b")

        #expect(provider.patternHint == "comparison")
    }

    @Test("3+ prose detected as writing pattern")
    func proseWritingPattern() {
        let provider = ClipboardHistoryProvider()
        provider.record(contentType: .prose, sourceApp: "com.apple.Notes")
        provider.record(contentType: .prose, sourceApp: "com.apple.Notes")
        provider.record(contentType: .prose, sourceApp: "com.apple.Notes")

        #expect(provider.patternHint == "writing")
    }

    @Test("Mixed content returns nil pattern")
    func mixedContentNilPattern() {
        let provider = ClipboardHistoryProvider()
        provider.record(contentType: .url, sourceApp: "com.apple.Safari")
        provider.record(contentType: .code, sourceApp: "com.microsoft.VSCode")
        provider.record(contentType: .prose, sourceApp: "com.apple.Notes")

        #expect(provider.patternHint == nil)
    }

    @Test("Buffer caps at bufferSize")
    func bufferCaps() {
        let provider = ClipboardHistoryProvider()
        for i in 0..<20 {
            provider.record(contentType: .prose, sourceApp: "com.app.\(i)")
        }
        #expect(provider.count == ClipboardHistoryProvider.bufferSize)
    }

    @Test("Clear empties the buffer")
    func clearEmpties() {
        let provider = ClipboardHistoryProvider()
        provider.record(contentType: .url, sourceApp: nil)
        provider.record(contentType: .url, sourceApp: nil)
        #expect(provider.count == 2)

        provider.clear()
        #expect(provider.count == 0)
        #expect(provider.patternHint == nil)
    }
}
