//
//  SettingsExporter.swift
//  Iridium
//

import AppKit
import Foundation
import OSLog
import UniformTypeIdentifiers

@MainActor
struct SettingsExporter {
    static func export(settings: SettingsStore, appPreferences: AppPreferences) {
        let bundle = SettingsBundle.from(settings: settings, appPreferences: appPreferences)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(bundle) else {
            Logger.app.error("Failed to encode settings for export")
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "Iridium Settings.json"
        panel.message = "Export your Iridium settings"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try data.write(to: url, options: .atomic)
            ToastManager.shared.show("Settings exported", icon: "square.and.arrow.up")
            Logger.app.info("Settings exported to \(url.path)")
        } catch {
            Logger.app.error("Failed to write settings file: \(error.localizedDescription)")
        }
    }
}
