//
//  AppIconView.swift
//  Iridium
//

import SwiftUI

struct AppIconView: View {
    let bundleID: String
    let size: CGFloat

    var body: some View {
        if let icon = BundleIDResolver.icon(for: bundleID) {
            Image(nsImage: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } else {
            Image(systemName: "app")
                .font(.system(size: size * 0.6))
                .frame(width: size, height: size)
                .foregroundStyle(.secondary)
        }
    }
}
