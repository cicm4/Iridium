//
//  IridiumUITests.swift
//  IridiumUITests
//
//  Created by Camilo on 3/22/26.
//

import XCTest

final class IridiumUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()

        // Iridium is a menu bar app (LSUIElement) — verify it launched
        XCTAssertTrue(app.state == .runningForeground || app.state == .runningBackground,
                      "Iridium should be running after launch")
    }
}
