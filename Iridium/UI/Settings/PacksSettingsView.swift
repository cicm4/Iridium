//
//  PacksSettingsView.swift
//  Iridium
//

import SwiftUI

struct PacksSettingsView: View {
    var body: some View {
        VStack {
            Text("Behavior Packs")
                .font(.headline)
            Text("Packs will appear here once the pack system is loaded.")
                .foregroundStyle(.secondary)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
