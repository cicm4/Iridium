//
//  UserDefaultsMock.swift
//  IridiumTests
//

import Foundation

extension UserDefaults {
    /// Creates an isolated UserDefaults instance for testing.
    static func makeMock() -> UserDefaults {
        let name = "com.iridium.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }
}
