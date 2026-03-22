//
//  UTIClassifierTests.swift
//  IridiumTests
//

import Testing
@testable import Iridium

struct UTIClassifierTests {
    let classifier = UTIClassifier()

    // MARK: - Source Code UTIs

    @Test func sourceCodeUTI() {
        #expect(classifier.classify(uti: "public.source-code") == .code)
    }

    @Test func swiftSourceUTI() {
        #expect(classifier.classify(uti: "com.apple.swift-source") == nil) // Doesn't contain "source-code"
    }

    @Test func sourceCodeVariant() {
        #expect(classifier.classify(uti: "public.sourcecode") == .code)
    }

    // MARK: - URL UTIs

    @Test func publicURL() {
        #expect(classifier.classify(uti: "public.url") == .url)
    }

    @Test func fileURL() {
        #expect(classifier.classify(uti: "public.file-url") == .url)
    }

    // MARK: - Image UTIs

    @Test func publicImage() {
        #expect(classifier.classify(uti: "public.image") == .image)
    }

    @Test func pngImage() {
        #expect(classifier.classify(uti: "public.png") == .image)
    }

    @Test func jpegImage() {
        #expect(classifier.classify(uti: "public.jpeg") == .image)
    }

    @Test func heicImage() {
        #expect(classifier.classify(uti: "public.heic") == .image)
    }

    // MARK: - File UTIs

    @Test func publicFile() {
        #expect(classifier.classify(uti: "public.file") == .file)
    }

    @Test func publicFolder() {
        #expect(classifier.classify(uti: "public.folder") == .file)
    }

    // MARK: - Text UTIs (should defer to pattern matching)

    @Test func plainTextReturnsNil() {
        // Plain text UTI should return nil to defer to pattern matching
        #expect(classifier.classify(uti: "public.plain-text") == nil)
    }

    @Test func utf8TextReturnsNil() {
        #expect(classifier.classify(uti: "public.utf8-plain-text") == nil)
    }

    // MARK: - Rich text

    @Test func rtfIsProse() {
        #expect(classifier.classify(uti: "public.rtf") == .prose)
    }

    @Test func htmlIsProse() {
        #expect(classifier.classify(uti: "public.html") == .prose)
    }

    // MARK: - Unknown UTIs

    @Test func unknownUTIReturnsNil() {
        #expect(classifier.classify(uti: "com.example.weird") == nil)
    }

    @Test func emptyStringReturnsNil() {
        #expect(classifier.classify(uti: "") == nil)
    }
}
