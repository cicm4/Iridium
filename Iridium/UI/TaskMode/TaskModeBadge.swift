//
//  TaskModeBadge.swift
//  Iridium
//
//  Small badge in the suggestion panel showing the active task.
//

import SwiftUI

struct TaskModeBadge: View {
    let taskName: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "target")
                .font(.system(size: 8))
            Text(taskName)
                .font(.system(size: 10))
                .lineLimit(1)
        }
        .foregroundStyle(.orange)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(.orange.opacity(0.12), in: Capsule())
    }
}
