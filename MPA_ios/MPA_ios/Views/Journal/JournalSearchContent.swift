//
//  JournalSearchContent.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/11/26.
//

import SwiftUI

struct JournalSearchContent: View {
    @Bindable var viewModel: JournalViewModel
    let keywordStages: [String: Int]
    let onOpenEntry: (Journal) -> Void
    let onOpenKeyword: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if viewModel.searchQuery.isEmpty {
                recentSearches
            } else if !viewModel.appliedSearchQuery.isEmpty {
                if viewModel.hasSearchResults {
                    keywordSuggestions
                    results
                } else {
                    noResults
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.TEXT_SECONDARY)
            .padding(.horizontal, JournalLayout.phoneGutter)
    }

    @ViewBuilder
    private var recentSearches: some View {
        if !viewModel.recentSearches.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                sectionLabel("최근 검색")
                ForEach(viewModel.recentSearches, id: \.self) { query in
                    HStack {
                        Button {
                            viewModel.applySearch(query)
                        } label: {
                            Text(query)
                                .font(.system(size: 16))
                                .foregroundStyle(Color.TEXT_PRIMARY)
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Button {
                            viewModel.removeRecentSearch(query)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.TEXT_TERTIARY)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(query) 삭제")
                    }
                    .padding(.horizontal, JournalLayout.phoneGutter)
                }
            }
        }
    }

    @ViewBuilder
    private var keywordSuggestions: some View {
        let suggestions = viewModel.searchKeywordMatches
        if !suggestions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("키워드")
                ForEach(suggestions) { suggestion in
                    Button {
                        onOpenKeyword(suggestion.name)
                    } label: {
                        keywordCard(suggestion)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, JournalLayout.phoneGutter)
                }
            }
        }
    }

    private func keywordCard(_ suggestion: JournalKeywordSuggestion) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.PRINCIPLE_SCALES[min(keywordStages[suggestion.name] ?? 0, Color.PRINCIPLE_SCALES.count - 1)])
                .frame(width: 24, height: 24)
            Text("\(Text(suggestion.name).bold()) 키워드로 모아 보기")
                .font(.system(size: 16))
                .foregroundStyle(Color.TEXT_PRIMARY)
                .lineLimit(1)
            Spacer(minLength: 0)
            Text("\(suggestion.count)편")
                .font(.system(size: 14))
                .foregroundStyle(Color.TEXT_SECONDARY)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.TEXT_SECONDARY)
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.AI_TINT))
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private var results: some View {
        let matches = viewModel.searchTitleBodyMatches
        if !matches.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("제목·본문 \(matches.count)편")
                VStack(spacing: 0) {
                    ForEach(Array(matches.enumerated()), id: \.element.id) { index, entry in
                        if index > 0 {
                            Rectangle().fill(Color.HAIRLINE).frame(height: 1)
                        }
                        JournalEntryRow(
                            entry: entry,
                            dateCaption: .month,
                            highlight: viewModel.appliedSearchQuery,
                            bodyText: entry.searchSnippet(for: viewModel.appliedSearchQuery),
                            keywordStages: keywordStages
                        )
                        .padding(.horizontal, JournalLayout.phoneGutter)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                        .onTapGesture { onOpenEntry(entry) }
                    }
                }
            }
        }
    }

    private var noResults: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28))
                .foregroundStyle(Color.TEXT_TERTIARY)
            Text("‘\(viewModel.appliedSearchQuery)’에 맞는 기록이 없어요")
                .font(.system(size: 15))
                .foregroundStyle(Color.TEXT_SECONDARY)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
    }
}
