//
//  SuggestionPanelView.swift
//  Iridium
//

import SwiftUI

struct SuggestionPanelView: View {
    @Environment(SuggestionPanelViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "sparkle")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Text("Suggestion")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            ForEach(Array(viewModel.suggestions.enumerated()), id: \.element.id) { index, suggestion in
                SuggestionRowView(
                    suggestion: suggestion,
                    isSelected: index == viewModel.selectedIndex,
                    isPrimary: index == 0
                )
                .onTapGesture {
                    viewModel.selectAtIndex(index)
                }

                if index == 0 && viewModel.suggestions.count > 1 {
                    Divider()
                        .padding(.horizontal, 12)
                }
            }
        }
        .padding(.bottom, 8)
        .frame(width: 280)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.separator, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
        .onKeyPress(.upArrow) {
            viewModel.moveSelectionUp()
            return .handled
        }
        .onKeyPress(.downArrow) {
            viewModel.moveSelectionDown()
            return .handled
        }
        .onKeyPress(.return) {
            viewModel.selectCurrent()
            return .handled
        }
        .onKeyPress(.escape) {
            viewModel.dismiss()
            return .handled
        }
    }
}
