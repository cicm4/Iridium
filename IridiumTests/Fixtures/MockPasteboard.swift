//
//  MockPasteboard.swift
//  IridiumTests
//

import AppKit
@testable import Iridium

final class MockPasteboard: PasteboardProviding, @unchecked Sendable {
    var changeCount: Int = 0
    var mockString: String?
    var mockTypes: [NSPasteboard.PasteboardType]?

    func string(forType dataType: NSPasteboard.PasteboardType) -> String? {
        mockString
    }

    func types() -> [NSPasteboard.PasteboardType]? {
        mockTypes
    }

    func simulateCopy(text: String, type: NSPasteboard.PasteboardType = .string) {
        changeCount += 1
        mockString = text
        mockTypes = [type]
    }
}
