//
//  AppDelegate.swift
//  Iridium
//

import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    let coordinator = AppCoordinator()
    private var menuBarManager: MenuBarManager?
    private var onboardingController: OnboardingWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarManager = MenuBarManager(coordinator: coordinator)
        menuBarManager?.setup()

        onboardingController = OnboardingWindowController()
        onboardingController?.showIfNeeded(coordinator: coordinator) { [weak self] in
            self?.onboardingController = nil
            self?.coordinator.start()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator.stop()
    }
}
