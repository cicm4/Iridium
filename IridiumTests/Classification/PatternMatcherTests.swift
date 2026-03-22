//
//  PatternMatcherTests.swift
//  IridiumTests
//

import Testing
@testable import Iridium

struct PatternMatcherTests {
    let matcher = PatternMatcher()

    // MARK: - URL Detection

    @Test func httpsURL() {
        let result = matcher.match(sample: "https://github.com/cicm/Iridium")
        #expect(result?.contentType == .url)
        #expect(result!.confidence >= 0.90)
    }

    @Test func httpURL() {
        let result = matcher.match(sample: "http://example.com")
        #expect(result?.contentType == .url)
    }

    @Test func ftpURL() {
        let result = matcher.match(sample: "ftp://files.example.com/data.zip")
        #expect(result?.contentType == .url)
    }

    @Test func wwwURL() {
        let result = matcher.match(sample: "www.example.com/path")
        #expect(result?.contentType == .url)
    }

    @Test func multilineTextIsNotURL() {
        let result = matcher.match(sample: "https://example.com\nsome other text\nand more lines")
        #expect(result?.contentType != .url)
    }

    // MARK: - Email Detection

    @Test func simpleEmail() {
        let result = matcher.match(sample: "user@example.com")
        #expect(result?.contentType == .email)
        #expect(result!.confidence >= 0.85)
    }

    @Test func emailWithSubdomain() {
        let result = matcher.match(sample: "admin@mail.company.co.uk")
        #expect(result?.contentType == .email)
    }

    @Test func notAnEmail() {
        // Multiple lines shouldn't be detected as email
        let result = matcher.match(sample: "hello\nuser@example.com")
        #expect(result?.contentType != .email)
    }

    // MARK: - Code Detection with Language

    @Test func swiftCode() {
        let result = matcher.match(sample: ClipboardSamples.swiftCode)
        #expect(result?.contentType == .code)
        #expect(result?.language == .swift)
    }

    @Test func pythonCode() {
        let result = matcher.match(sample: ClipboardSamples.pythonCode)
        #expect(result?.contentType == .code)
        #expect(result?.language == .python)
    }

    @Test func javascriptCode() {
        let result = matcher.match(sample: ClipboardSamples.javascriptCode)
        #expect(result?.contentType == .code)
        #expect(result?.language == .javascript)
    }

    @Test func typescriptCode() {
        let result = matcher.match(sample: ClipboardSamples.typescriptCode)
        #expect(result?.contentType == .code)
        #expect(result?.language == .typescript)
    }

    @Test func htmlCode() {
        let result = matcher.match(sample: ClipboardSamples.htmlCode)
        #expect(result?.contentType == .code)
        #expect(result?.language == .html)
    }

    @Test func shellScript() {
        let result = matcher.match(sample: ClipboardSamples.shellScript)
        #expect(result?.contentType == .code)
        #expect(result?.language == .shell)
    }

    @Test func sqlQuery() {
        let result = matcher.match(sample: ClipboardSamples.sqlQuery)
        #expect(result?.contentType == .code)
        #expect(result?.language == .sql)
    }

    @Test func rustCode() {
        let result = matcher.match(sample: ClipboardSamples.rustCode)
        #expect(result?.contentType == .code)
        #expect(result?.language == .rust)
    }

    @Test func goCode() {
        let result = matcher.match(sample: ClipboardSamples.goCode)
        #expect(result?.contentType == .code)
        #expect(result?.language == .go)
    }

    // MARK: - Prose Detection

    @Test func proseText() {
        let result = matcher.match(sample: ClipboardSamples.prose)
        #expect(result?.contentType == .prose)
    }

    // MARK: - Generic Code Detection

    @Test func genericCodeWithBraces() {
        let result = matcher.match(sample: "if (x != y) { return x == z; } // comment")
        #expect(result?.contentType == .code)
    }

    // MARK: - Edge Cases

    @Test func veryShortText() {
        let result = matcher.match(sample: "hi")
        #expect(result == nil)
    }

    @Test func emptyString() {
        let result = matcher.match(sample: "")
        #expect(result == nil)
    }

    // MARK: - Language Detector Directly

    @Test func detectSwiftLanguage() {
        let lang = matcher.detectCodeLanguage(ClipboardSamples.swiftCode)
        #expect(lang == .swift)
    }

    @Test func detectPythonLanguage() {
        let lang = matcher.detectCodeLanguage(ClipboardSamples.pythonCode)
        #expect(lang == .python)
    }
}
