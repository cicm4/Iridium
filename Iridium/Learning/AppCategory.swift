//
//  AppCategory.swift
//  Iridium
//
//  Broad application categories derived from LSApplicationCategoryType.
//  Used by Task Mode (Phase 2) and Adaptive Learning for category-based boosts.
//

import Foundation

enum AppCategory: String, Codable, Sendable, CaseIterable {
    case development
    case creativity
    case productivity
    case communication
    case research
    case media
    case utility
    case other

    /// Maps an LSApplicationCategoryType string to an AppCategory.
    /// See: https://developer.apple.com/documentation/bundleresources/information_property_list/lsapplicationcategorytype
    static func from(lsCategoryType: String?) -> AppCategory {
        guard let cat = lsCategoryType?.lowercased() else { return .other }

        if cat.contains("developer-tools") { return .development }
        if cat.contains("graphics-design") || cat.contains("photography") || cat.contains("music") { return .creativity }
        if cat.contains("video") || cat.contains("entertainment") { return .media }
        if cat.contains("productivity") || cat.contains("business") || cat.contains("finance") { return .productivity }
        if cat.contains("social-networking") || cat.contains("communication") { return .communication }
        if cat.contains("education") || cat.contains("reference") || cat.contains("news") { return .research }
        if cat.contains("utilities") { return .utility }

        return .other
    }

    /// Maps well-known bundle IDs to categories as a fallback when
    /// LSApplicationCategoryType is missing or generic.
    static func from(bundleID: String) -> AppCategory {
        let id = bundleID.lowercased()

        // Development tools
        if id.contains("xcode") || id.contains("vscode") || id.contains("jetbrains")
            || id.contains("cursor") || id.contains("todesktop.230313mzl4w4u92")
            || id.contains("sublimetext") || id.contains("zed") || id.contains("nova")
            || id.contains("terminal") || id.contains("iterm") || id.contains("warp")
        { return .development }

        // Creativity
        if id.contains("figma") || id.contains("sketch") || id.contains("photoshop")
            || id.contains("illustrator") || id.contains("affinity") || id.contains("garageband")
            || id.contains("logic") || id.contains("final-cut") || id.contains("davinci")
        { return .creativity }

        // Media
        if id.contains("vlc") || id.contains("iina") || id.contains("spotify")
            || id.contains("music") || id.contains("tv") || id.contains("quicktime")
        { return .media }

        // Communication
        if id.contains("mail") || id.contains("outlook") || id.contains("slack")
            || id.contains("discord") || id.contains("telegram") || id.contains("messages")
            || id.contains("zoom") || id.contains("teams") || id.contains("facetime")
        { return .communication }

        // Research
        if id.contains("safari") || id.contains("chrome") || id.contains("firefox")
            || id.contains("arc") || id.contains("brave") || id.contains("obsidian")
            || id.contains("notion") || id.contains("devonthink")
        { return .research }

        // Productivity
        if id.contains("pages") || id.contains("word") || id.contains("numbers")
            || id.contains("excel") || id.contains("keynote") || id.contains("powerpoint")
            || id.contains("notes") || id.contains("reminders") || id.contains("todoist")
            || id.contains("things") || id.contains("omnifocus") || id.contains("calendar")
        { return .productivity }

        // Utility
        if id.contains("finder") || id.contains("preview") || id.contains("automator")
            || id.contains("shortcuts") || id.contains("activity-monitor")
            || id.contains("raycast") || id.contains("alfred")
        { return .utility }

        return .other
    }
}
