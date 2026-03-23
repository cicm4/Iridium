//
//  SuggestionPanelView.swift
//  Iridium
//

import SwiftUI

struct SuggestionPanelView: View {
    @Environment(SuggestionPanelViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header
            HStack {
                Image(systemName: "sparkle")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Text(viewModel.isSearching ? "Search" : "Suggestion")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            // Search bar — visible when user starts typing
            if viewModel.isSearching {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Text(viewModel.searchQuery)
                        .font(.body)
                        .lineLimit(1)
                    Spacer()
                    if !viewModel.searchQuery.isEmpty {
                        Text("esc to clear")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
                .padding(.horizontal, 8)

                Divider()
                    .padding(.horizontal, 12)
            }

            // Suggestions or search results
            let displayed = viewModel.displayedSuggestions
            if displayed.isEmpty && viewModel.isSearching {
                Text("No apps found")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(displayed.enumerated()), id: \.element.id) { index, suggestion in
                    SuggestionRowView(
                        suggestion: suggestion,
                        isSelected: index == viewModel.selectedIndex,
                        isPrimary: index == 0 && !viewModel.isSearching
                    )
                    .onTapGesture {
                        viewModel.selectAtIndex(index)
                    }

                    if index == 0 && displayed.count > 1 && !viewModel.isSearching {
                        Divider()
                            .padding(.horizontal, 12)
                    }
                }
            }

            // Search hint at bottom when not searching
            if !viewModel.isSearching && !displayed.isEmpty {
                Divider()
                    .padding(.horizontal, 12)
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.caption2)
                    Text("Type to search all apps")
                        .font(.caption2)
                }
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 12)
                .padding(.bottom, 2)
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
            if viewModel.isSearching {
                viewModel.searchQuery = ""
                viewModel.searchResults = []
            } else {
                viewModel.dismiss()
            }
            return .handled
        }
    }
}
