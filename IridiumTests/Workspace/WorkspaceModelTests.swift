//
//  WorkspaceModelTests.swift
//  IridiumTests
//

import Foundation
import Testing
@testable import Iridium

@Suite("WorkspaceModel")
struct WorkspaceModelTests {

    @Test("bundleIDs returns all app bundle IDs")
    func bundleIDs() {
        let workspace = Workspace(
            name: "Dev",
            apps: [
                WorkspaceApp(bundleID: "com.apple.dt.Xcode"),
                WorkspaceApp(bundleID: "com.apple.Safari"),
            ]
        )
        #expect(workspace.bundleIDs == Set(["com.apple.dt.Xcode", "com.apple.Safari"]))
    }

    @Test("runningCount counts running workspace apps")
    func runningCount() {
        let workspace = Workspace(
            name: "Dev",
            apps: [
                WorkspaceApp(bundleID: "com.apple.dt.Xcode"),
                WorkspaceApp(bundleID: "com.apple.Safari"),
                WorkspaceApp(bundleID: "com.apple.Terminal"),
            ]
        )

        let running: Set<String> = ["com.apple.dt.Xcode", "com.apple.Safari", "com.spotify.client"]
        #expect(workspace.runningCount(in: running) == 2)
    }

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        let workspace = Workspace(
            name: "Test",
            apps: [
                WorkspaceApp(bundleID: "com.app.a", region: .init(x: 0, y: 0, width: 0.5, height: 1)),
                WorkspaceApp(bundleID: "com.app.b", region: .init(x: 0.5, y: 0, width: 0.5, height: 1)),
            ],
            spaceIndex: 2,
            iconSystemName: "star"
        )

        let data = try JSONEncoder().encode(workspace)
        let decoded = try JSONDecoder().decode(Workspace.self, from: data)

        #expect(decoded.name == workspace.name)
        #expect(decoded.apps.count == 2)
        #expect(decoded.spaceIndex == 2)
        #expect(decoded.iconSystemName == "star")
        #expect(decoded.apps[0].region.width == 0.5)
    }

    @Test("WorkspaceApp default region is fullscreen")
    func defaultRegion() {
        let app = WorkspaceApp(bundleID: "com.test.app")
        #expect(app.region.x == 0)
        #expect(app.region.y == 0)
        #expect(app.region.width == 1)
        #expect(app.region.height == 1)
    }
}
