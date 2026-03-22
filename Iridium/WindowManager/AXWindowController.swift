//
//  AXWindowController.swift
//  Iridium
//

import AppKit
import OSLog

struct AXWindowController: Sendable {
    /// Gets the frontmost window of the given application.
    @MainActor
    static func frontmostWindow(for app: NSRunningApplication) -> AXUIElement? {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)

        var focusedWindow: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)

        guard result == .success else {
            Logger.windowManager.debug("Cannot get focused window for \(app.bundleIdentifier ?? "unknown"): \(result.rawValue)")
            return nil
        }

        return (focusedWindow as! AXUIElement)
    }

    /// Gets the current position of a window.
    static func getPosition(of window: AXUIElement) -> CGPoint? {
        var positionValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue) == .success else {
            return nil
        }

        var point = CGPoint.zero
        guard AXValueGetValue(positionValue as! AXValue, .cgPoint, &point) else { return nil }
        return point
    }

    /// Gets the current size of a window.
    static func getSize(of window: AXUIElement) -> CGSize? {
        var sizeValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue) == .success else {
            return nil
        }

        var size = CGSize.zero
        guard AXValueGetValue(sizeValue as! AXValue, .cgSize, &size) else { return nil }
        return size
    }

    /// Sets the position of a window.
    static func setPosition(of window: AXUIElement, to point: CGPoint) -> Bool {
        var mutablePoint = point
        guard let value = AXValueCreate(.cgPoint, &mutablePoint) else { return false }
        return AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, value) == .success
    }

    /// Sets the size of a window.
    static func setSize(of window: AXUIElement, to size: CGSize) -> Bool {
        var mutableSize = size
        guard let value = AXValueCreate(.cgSize, &mutableSize) else { return false }
        return AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, value) == .success
    }

    /// Moves and resizes a window to the given frame.
    static func setFrame(of window: AXUIElement, to frame: CGRect) -> Bool {
        let positionOK = setPosition(of: window, to: frame.origin)
        let sizeOK = setSize(of: window, to: frame.size)
        return positionOK && sizeOK
    }
}
