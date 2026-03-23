//
//  QuickActionResolver.swift
//  Iridium
//

import AppKit
import Foundation

protocol QuickActionResolving: Sendable {
    @MainActor
    func resolve(bundleID: String, contentType: ContentType, clipboardText: String?) -> [QuickAction]
}

struct QuickActionResolver: QuickActionResolving {
    /// Well-known browser bundle IDs.
    static let browserBundleIDs: Set<String> = [
        "com.apple.Safari",
        "com.google.Chrome",
        "com.mozilla.firefox",
        "company.thebrowser.Browser", // Arc
        "com.brave.Browser",
        "com.microsoft.edgemac",
        "com.vivaldi.Vivaldi",
    ]

    @MainActor
    func resolve(bundleID: String, contentType: ContentType, clipboardText: String?) -> [QuickAction] {
        var actions: [QuickAction] = []

        guard let text = clipboardText, !text.isEmpty else { return actions }

        switch contentType {
        case .url:
            if Self.browserBundleIDs.contains(bundleID) || bundleID == "com.apple.finder" {
                actions.append(QuickAction(
                    title: "Open URL",
                    icon: "globe",
                    handler: {
                        AppLauncher.openURL(text, inApp: bundleID)
                    }
                ))
            }

        case .file:
            if bundleID == "com.apple.finder" {
                actions.append(QuickAction(
                    title: "Reveal in Finder",
                    icon: "folder",
                    handler: {
                        AppLauncher.revealInFinder(text)
                    }
                ))
            } else {
                actions.append(QuickAction(
                    title: "Open File",
                    icon: "doc",
                    handler: {
                        AppLauncher.openFile(text, inApp: bundleID)
                    }
                ))
            }

        case .email:
            let mailBundleIDs: Set<String> = [
                "com.apple.mail",
                "com.readdle.smartemail",
                "com.microsoft.Outlook",
            ]
            if mailBundleIDs.contains(bundleID) {
                actions.append(QuickAction(
                    title: "Compose Email",
                    icon: "envelope",
                    handler: {
                        AppLauncher.openURL("mailto:\(text)", inApp: bundleID)
                    }
                ))
            }

        default:
            break
        }

        return actions
    }
}
