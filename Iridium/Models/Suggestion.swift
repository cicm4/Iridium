//
//  Suggestion.swift
//  Iridium
//

import Foundation

enum SuggestionKind: Sendable, Equatable {
    case app
    case workspace(workspaceID: UUID)

    /// Extracts workspace ID from a "workspace:UUID" bundle ID string.
    static func from(bundleID: String) -> SuggestionKind {
        if bundleID.hasPrefix("workspace:"),
           let uuid = UUID(uuidString: String(bundleID.dropFirst("workspace:".count)))
        {
            return .workspace(workspaceID: uuid)
        }
        return .app
    }
}

struct Suggestion: Sendable, Identifiable, Equatable {
    let id: String
    let bundleID: String
    let confidence: Double
    let sourcePackID: String
    let kind: SuggestionKind
    let contextHint: String?

    init(bundleID: String, confidence: Double, sourcePackID: String, kind: SuggestionKind = .app, contextHint: String? = nil) {
        self.id = "\(sourcePackID):\(bundleID)"
        self.bundleID = bundleID
        self.confidence = confidence
        self.sourcePackID = sourcePackID
        self.kind = kind
        self.contextHint = contextHint
    }

    /// Whether this is a workspace suggestion.
    var isWorkspace: Bool {
        if case .workspace = kind { return true }
        return false
    }

    /// The workspace ID if this is a workspace suggestion.
    var workspaceID: UUID? {
        if case .workspace(let id) = kind { return id }
        return nil
    }
}
