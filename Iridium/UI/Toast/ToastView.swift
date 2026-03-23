//
//  ToastView.swift
//  Iridium
//

import SwiftUI

struct ToastView: View {
    let item: ToastItem

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: item.icon)
                .font(.body)
                .foregroundStyle(.tint)

            Text(item.message)
                .font(.callout.weight(.medium))
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(.separator, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.message)
    }
}
