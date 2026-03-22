//
//  SuggestionRowView.swift
//  Iridium
//

import SwiftUI

struct SuggestionRowView: View {
    let suggestion: SuggestionPanelViewModel.ResolvedSuggestion
    let isSelected: Bool
    let isPrimary: Bool

    var body: some View {
        HStack(spacing: 10) {
            if let icon = suggestion.icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: isPrimary ? 36 : 24, height: isPrimary ? 36 : 24)
            } else {
                Image(systemName: "app")
                    .font(isPrimary ? .title2 : .body)
                    .frame(width: isPrimary ? 36 : 24, height: isPrimary ? 36 : 24)
                    .foregroundStyle(.secondary)
            }

            Text(suggestion.name)
                .font(isPrimary ? .headline : .body)
                .lineLimit(1)

            Spacer()

            if suggestion.shortcutIndex <= 3 {
                Text("\u{2318}\(suggestion.shortcutIndex)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
            }

            if isPrimary {
                Image(systemName: "return")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, isPrimary ? 10 : 6)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
    }
}
