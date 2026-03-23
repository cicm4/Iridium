//
//  BrowserTabProvider.swift
//  Iridium
//
//  Reads the focused browser tab's URL and title via Accessibility API.
//  Supports Safari, Chrome, Firefox, Arc.
//

import AppKit
import Foundation
import OSLog

@MainActor
final class BrowserTabProvider: SignalProvider {
    struct BrowserTabSnapshot: Sendable {
        let domain: String?
        let title: String?
    }

    /// Known browser bundle IDs.
    static let browserBundleIDs: Set<String> = [
        "com.apple.Safari",
        "com.google.Chrome",
        "org.mozilla.firefox",
        "company.thebrowser.Browser",  // Arc
        "com.brave.Browser",
        "com.microsoft.edgemac",
        "com.vivaldi.Vivaldi",
    ]

    private(set) var currentSnapshot: BrowserTabSnapshot?

    func start() {
        update()
    }

    func stop() {
        currentSnapshot = nil
    }

    /// Updates the current snapshot by reading the frontmost browser's active tab.
    func update() {
        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              let bundleID = frontApp.bundleIdentifier,
              Self.browserBundleIDs.contains(bundleID)
        else {
            currentSnapshot = nil
            return
        }

        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)

        // Try to get the focused window's title (which often contains the tab title)
        var windowValue: CFTypeRef?
        let windowResult = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &windowValue)

        guard windowResult == .success, let window = windowValue else {
            currentSnapshot = nil
            return
        }

        var titleValue: CFTypeRef?
        AXUIElementCopyAttributeValue(window as! AXUIElement, kAXTitleAttribute as CFString, &titleValue)
        let title = titleValue as? String

        // Try to extract URL from the address bar
        let url = extractURL(from: window as! AXUIElement)
        let domain = url.flatMap { URL(string: $0)?.host }

        currentSnapshot = BrowserTabSnapshot(domain: domain, title: title)
        Logger.signals.debug("Browser tab: domain=\(domain ?? "nil"), title=\(title ?? "nil")")
    }

    /// Attempts to extract the URL from a browser's address bar via AX API.
    private func extractURL(from window: AXUIElement) -> String? {
        // Most browsers expose the URL in a text field child element
        // with role "AXTextField" and subrole "AXSearchField" or description containing "address"
        var children: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(window, kAXChildrenAttribute as CFString, &children)
        guard result == .success, let elements = children as? [AXUIElement] else { return nil }

        return findURLField(in: elements, depth: 3)
    }

    private func findURLField(in elements: [AXUIElement], depth: Int) -> String? {
        guard depth > 0 else { return nil }

        for element in elements {
            var role: CFTypeRef?
            AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role)

            if let roleStr = role as? String, roleStr == "AXTextField" {
                var desc: CFTypeRef?
                AXUIElementCopyAttributeValue(element, kAXDescriptionAttribute as CFString, &desc)
                let descStr = (desc as? String)?.lowercased() ?? ""

                if descStr.contains("address") || descStr.contains("url") || descStr.contains("search") {
                    var value: CFTypeRef?
                    AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value)
                    if let urlStr = value as? String, !urlStr.isEmpty {
                        // Normalize: add https:// if missing
                        if urlStr.hasPrefix("http://") || urlStr.hasPrefix("https://") {
                            return urlStr
                        }
                        return "https://\(urlStr)"
                    }
                }
            }

            // Recurse into children
            var subChildren: CFTypeRef?
            AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &subChildren)
            if let subs = subChildren as? [AXUIElement] {
                if let found = findURLField(in: subs, depth: depth - 1) {
                    return found
                }
            }
        }

        return nil
    }
}
