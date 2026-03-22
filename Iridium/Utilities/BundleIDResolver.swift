//
//  BundleIDResolver.swift
//  Iridium
//

import AppKit

struct BundleIDResolver: Sendable {
    struct AppInfo: Sendable {
        let name: String
        let bundleID: String
        let path: String?
    }

    @MainActor
    static func resolve(bundleID: String) -> AppInfo? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }

        let name = url.deletingPathExtension().lastPathComponent
        return AppInfo(name: name, bundleID: bundleID, path: url.path)
    }

    @MainActor
    static func icon(for bundleID: String) -> NSImage? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: url.path)
    }
}
