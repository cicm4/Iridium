//
//  TimeSignalProvider.swift
//  Iridium
//

import Foundation

struct TimeSignalProvider: Sendable {
    var currentHourOfDay: Int {
        Calendar.current.component(.hour, from: Date())
    }
}
