//
//  AppDelegate.swift
//  Iridium
//

import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    let coordinator = AppCoordinator()
    private var menuBarManager: MenuBarManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarManager = MenuBarManager(coordinator: coordinator)
        menuBarManager?.setup()
        coordinator.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator.stop()
    }
}
