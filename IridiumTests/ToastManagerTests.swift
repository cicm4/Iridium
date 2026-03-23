//
//  ToastManagerTests.swift
//  IridiumTests
//

import Testing
import Foundation
@testable import Iridium

@MainActor
struct ToastManagerTests {
    @Test func showSetsCurrentToast() {
        // ToastManager is a singleton, so if another test triggered a toast,
        // our toast may be queued. We verify the toast item model is correct.
        let item = ToastItem(message: "Test message", icon: "checkmark")
        #expect(item.message == "Test message")
        #expect(item.icon == "checkmark")
        #expect(item.duration == 2.0)

        // Also verify calling show does not crash
        let manager = ToastManager.shared
        manager.show("Test message", icon: "checkmark")
        #expect(manager.currentToast != nil)
    }

    @Test func toastItemHasDefaultDuration() {
        let item = ToastItem(message: "Hello", icon: "star")
        #expect(item.duration == 2.0)
    }

    @Test func toastItemSupportsCustomDuration() {
        let item = ToastItem(message: "Hello", icon: "star", duration: 5.0)
        #expect(item.duration == 5.0)
    }

    @Test func toastItemHasUniqueIDs() {
        let item1 = ToastItem(message: "A", icon: "star")
        let item2 = ToastItem(message: "B", icon: "star")
        #expect(item1.id != item2.id)
    }
}
