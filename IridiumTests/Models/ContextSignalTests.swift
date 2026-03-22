//
//  ContextSignalTests.swift
//  IridiumTests
//

import Testing
@testable import Iridium

struct ContextSignalTests {
    @Test func defaultInitialization() {
        let signal = ContextSignal()
        #expect(signal.clipboardUTI == nil)
        #expect(signal.clipboardSample == nil)
        #expect(signal.contentType == nil)
        #expect(signal.language == nil)
        #expect(signal.frontmostAppBundleID == nil)
        #expect(signal.hourOfDay >= 0 && signal.hourOfDay <= 23)
        #expect(signal.displayCount == 1)
        #expect(signal.focusModeActive == false)
    }

    @Test func customInitialization() {
        let signal = ContextSignal(
            clipboardUTI: "public.plain-text",
            clipboardSample: "hello",
            contentType: .code,
            language: .swift,
            frontmostAppBundleID: "com.apple.Safari",
            hourOfDay: 14,
            displayCount: 2,
            focusModeActive: true
        )
        #expect(signal.clipboardUTI == "public.plain-text")
        #expect(signal.clipboardSample == "hello")
        #expect(signal.contentType == .code)
        #expect(signal.language == .swift)
        #expect(signal.frontmostAppBundleID == "com.apple.Safari")
        #expect(signal.hourOfDay == 14)
        #expect(signal.displayCount == 2)
        #expect(signal.focusModeActive == true)
    }

    @Test func maxSampleBytesConstant() {
        #expect(ContextSignal.maxSampleBytes == 512)
    }
}
