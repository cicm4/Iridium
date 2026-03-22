//
//  SettingsView.swift
//  Iridium
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            PacksSettingsView()
                .tabItem {
                    Label("Packs", systemImage: "puzzlepiece")
                }

            LayoutSettingsView()
                .tabItem {
                    Label("Layouts", systemImage: "rectangle.split.3x3")
                }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 480, height: 360)
    }
}
