//
//  ClipboardMonitorTests.swift
//  IridiumTests
//

import Testing
import AppKit
@testable import Iridium

@MainActor
struct ClipboardMonitorTests {
    // MARK: - Change Detection

    @Test func detectsClipboardChange() async throws {
        let mockPasteboard = MockPasteboard()
        let monitor = ClipboardMonitor(pasteboard: mockPasteboard, pollInterval: 0.05)

        var receivedSnapshot: ClipboardMonitor.ClipboardSnapshot?
        monitor.onClipboardChange { snapshot in
            receivedSnapshot = snapshot
        }

        monitor.start()

        // Simulate a copy
        mockPasteboard.simulateCopy(text: "hello world", type: .string)

        // Wait for the polling timer to fire
        try await Task.sleep(for: .milliseconds(100))

        #expect(receivedSnapshot != nil)
        #expect(receivedSnapshot?.sample == "hello world")
        #expect(receivedSnapshot?.uti == NSPasteboard.PasteboardType.string.rawValue)

        monitor.stop()
    }

    @Test func truncatesSampleAt512Bytes() async throws {
        let mockPasteboard = MockPasteboard()
        let monitor = ClipboardMonitor(pasteboard: mockPasteboard, pollInterval: 0.05)

        var receivedSnapshot: ClipboardMonitor.ClipboardSnapshot?
        monitor.onClipboardChange { snapshot in
            receivedSnapshot = snapshot
        }

        monitor.start()

        let longText = String(repeating: "a", count: 1000)
        mockPasteboard.simulateCopy(text: longText, type: .string)

        try await Task.sleep(for: .milliseconds(100))

        #expect(receivedSnapshot?.sample?.count == ContextSignal.maxSampleBytes)

        monitor.stop()
    }

    @Test func doesNotFireWithoutChange() async throws {
        let mockPasteboard = MockPasteboard()
        let monitor = ClipboardMonitor(pasteboard: mockPasteboard, pollInterval: 0.05)

        var callCount = 0
        monitor.onClipboardChange { _ in
            callCount += 1
        }

        monitor.start()

        // Wait without changing pasteboard
        try await Task.sleep(for: .milliseconds(150))

        #expect(callCount == 0)

        monitor.stop()
    }

    @Test func stopsEmittingAfterStop() async throws {
        let mockPasteboard = MockPasteboard()
        let monitor = ClipboardMonitor(pasteboard: mockPasteboard, pollInterval: 0.05)

        var callCount = 0
        monitor.onClipboardChange { _ in
            callCount += 1
        }

        monitor.start()
        mockPasteboard.simulateCopy(text: "first")
        try await Task.sleep(for: .milliseconds(100))

        monitor.stop()

        let countAfterStop = callCount
        mockPasteboard.simulateCopy(text: "second")
        try await Task.sleep(for: .milliseconds(100))

        #expect(callCount == countAfterStop)
    }

    // MARK: - Nil Content

    @Test func handlesNilStringGracefully() async throws {
        let mockPasteboard = MockPasteboard()
        mockPasteboard.mockString = nil
        mockPasteboard.mockTypes = [.string]
        let monitor = ClipboardMonitor(pasteboard: mockPasteboard, pollInterval: 0.05)

        var receivedSnapshot: ClipboardMonitor.ClipboardSnapshot?
        monitor.onClipboardChange { snapshot in
            receivedSnapshot = snapshot
        }

        monitor.start()
        mockPasteboard.changeCount += 1

        try await Task.sleep(for: .milliseconds(100))

        #expect(receivedSnapshot?.sample == nil)
        #expect(receivedSnapshot?.uti != nil)

        monitor.stop()
    }
}
