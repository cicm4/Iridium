//
//  IridiumApp.swift
//  Iridium
//
//  Created by Camilo on 3/22/26.
//

import SwiftUI

@main
struct IridiumApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(appPreferences: appDelegate.coordinator.appPreferences)
                .environment(appDelegate.coordinator)
        }
    }
}
