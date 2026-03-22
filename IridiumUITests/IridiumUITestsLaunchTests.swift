//
//  IridiumUITestsLaunchTests.swift
//  IridiumUITests
//
//  Created by Camilo on 3/22/26.
//

import XCTest

final class IridiumUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Menu bar app — verify it's running (no main window to screenshot)
        XCTAssertTrue(app.state == .runningForeground || app.state == .runningBackground,
                      "Iridium should be running after launch")
    }
}
