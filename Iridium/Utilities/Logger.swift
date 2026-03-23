//
//  Logger.swift
//  Iridium
//

import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "cicm.Iridium"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let signals = Logger(subsystem: subsystem, category: "signals")
    static let classification = Logger(subsystem: subsystem, category: "classification")
    static let packs = Logger(subsystem: subsystem, category: "packs")
    static let prediction = Logger(subsystem: subsystem, category: "prediction")
    static let windowManager = Logger(subsystem: subsystem, category: "windowManager")
    static let ui = Logger(subsystem: subsystem, category: "ui")
    static let learning = Logger(subsystem: subsystem, category: "learning")
    static let taskMode = Logger(subsystem: subsystem, category: "taskMode")
}
