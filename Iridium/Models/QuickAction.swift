//
//  QuickAction.swift
//  Iridium
//

import Foundation

struct QuickAction: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let icon: String
    let handler: @Sendable @MainActor () -> Void
}
