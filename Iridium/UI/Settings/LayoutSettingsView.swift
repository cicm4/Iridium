//
//  LayoutSettingsView.swift
//  Iridium
//

import SwiftUI

struct LayoutSettingsView: View {
    var body: some View {
        VStack {
            Text("Window Layouts")
                .font(.headline)
            Text("Layout presets will appear here once the window manager is loaded.")
                .foregroundStyle(.secondary)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
