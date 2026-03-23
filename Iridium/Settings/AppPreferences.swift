//
//  AppPreferences.swift
//  Iridium
//

import Foundation
import Observation

@Observable
final class AppPreferences {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let ids = defaults.stringArray(forKey: Keys.excludedBundleIDs) {
            self.excludedBundleIDs = Set(ids)
        }
        if let ids = defaults.stringArray(forKey: Keys.pinnedBundleIDs) {
            self.pinnedBundleIDs = Set(ids)
        }
        if let data = defaults.data(forKey: Keys.customMappings),
           let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) {
            self.customMappings = decoded
        }
    }

    var excludedBundleIDs: Set<String> = [] {
        didSet { defaults.set(Array(excludedBundleIDs), forKey: Keys.excludedBundleIDs) }
    }

    var pinnedBundleIDs: Set<String> = [] {
        didSet { defaults.set(Array(pinnedBundleIDs), forKey: Keys.pinnedBundleIDs) }
    }

    /// Maps content type raw value to array of bundle IDs
    var customMappings: [String: [String]] = [:] {
        didSet {
            if let data = try? JSONEncoder().encode(customMappings) {
                defaults.set(data, forKey: Keys.customMappings)
            }
        }
    }

    private enum Keys {
        static let excludedBundleIDs = "excludedBundleIDs"
        static let pinnedBundleIDs = "pinnedBundleIDs"
        static let customMappings = "customMappings"
    }
}
