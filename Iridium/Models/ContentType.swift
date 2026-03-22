//
//  ContentType.swift
//  Iridium
//

import Foundation

enum ContentType: String, Sendable, Codable, CaseIterable {
    case code
    case url
    case email
    case prose
    case image
    case file
    case unknown
}
