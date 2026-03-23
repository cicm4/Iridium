//
//  SettingsImporter.swift
//  Iridium
//

import AppKit
import Foundation
import OSLog
import UniformTypeIdentifiers

@MainActor
struct SettingsImporter {
    enum ImportError: Error, LocalizedError {
        case incompatibleVersion(Int)
        case decodingFailed(String)

        var errorDescription: String? {
            switch self {
            case .incompatibleVersion(let version):
                return "Incompatible settings version: \(version). Expected \(SettingsBundle.currentSchemaVersion)."
            case .decodingFailed(let detail):
                return "Failed to read settings file: \(detail)"
            }
        }
    }

    static func importSettings(to settings: SettingsStore, appPreferences: AppPreferences) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.message = "Import Iridium settings"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let bundle = try load(from: url)
            try validate(bundle)

            // Confirm overwrite
            let alert = NSAlert()
            alert.messageText = "Import Settings?"
            alert.informativeText = "This will replace all your current settings. This cannot be undone."
            alert.addButton(withTitle: "Import")
            alert.addButton(withTitle: "Cancel")
            alert.alertStyle = .warning

            guard alert.runModal() == .alertFirstButtonReturn else { return }

            bundle.apply(to: settings, appPreferences: appPreferences)
            ToastManager.shared.show("Settings imported", icon: "square.and.arrow.down")
            Logger.app.info("Settings imported from \(url.path)")
        } catch {
            let alert = NSAlert()
            alert.messageText = "Import Failed"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .critical
            alert.runModal()
        }
    }

    static func load(from url: URL) throws -> SettingsBundle {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(SettingsBundle.self, from: data)
        } catch {
            throw ImportError.decodingFailed(error.localizedDescription)
        }
    }

    static func validate(_ bundle: SettingsBundle) throws {
        if bundle.schemaVersion > SettingsBundle.currentSchemaVersion {
            throw ImportError.incompatibleVersion(bundle.schemaVersion)
        }
    }
}
