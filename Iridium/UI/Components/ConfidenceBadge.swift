//
//  ConfidenceBadge.swift
//  Iridium
//

import SwiftUI

struct ConfidenceBadge: View {
    let confidence: Double

    var body: some View {
        Text("\(Int(confidence * 100))%")
            .font(.caption2)
            .foregroundStyle(color)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(color.opacity(0.1), in: Capsule())
    }

    private var color: Color {
        if confidence >= 0.85 { return .green }
        if confidence >= 0.65 { return .orange }
        return .secondary
    }
}
