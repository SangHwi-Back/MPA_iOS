//
//  JournalEntryRow.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/11/26.
//

import SwiftUI

struct JournalEntryRow: View {
    enum DateCaption { case weekday, month }

    let entry: Journal
    var dateCaption: DateCaption = .weekday
    var highlight: String? = nil
    var bodyText: String? = nil
    let keywordStages: [String: Int]
    var thumbnailSize: CGFloat = 60
    var showsThumbnailGlyph: Bool = true
    var chipTextColor: Color = .AI_ACCENT

    private var chips: [JournalKeyword] {
        Array(entry.visibleKeywords.prefix(Journal.maxKeywordsInList))
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 2) {
                Text(JournalDateText.day(entry.day))
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                Text(dateCaption == .weekday ? JournalDateText.weekday(entry.day) : JournalDateText.month(entry.day))
                    .font(.system(size: 13))
                    .foregroundStyle(Color.TEXT_SECONDARY)
            }
            .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(highlighted(entry.displayTitle))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                    .lineLimit(1)

                Text(highlighted(bodyText ?? entry.previewText))
                    .font(.system(size: 14))
                    .foregroundStyle(Color.TEXT_SECONDARY)
                    .lineSpacing(4)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                keywordRow
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let photo = entry.thumbnail {
                JournalThumbnail(photo: photo, extraCount: entry.photos.count - 1, size: thumbnailSize, showsGlyph: showsThumbnailGlyph)
            }
        }
    }

    @ViewBuilder
    private var keywordRow: some View {
        if entry.showsKeywords, !chips.isEmpty {
            HStack(spacing: 6) {
                ForEach(chips, id: \.name) { keyword in
                    JournalKeywordChip(
                        name: keyword.name,
                        stage: keywordStages[keyword.name] ?? 0,
                        isEmphasized: keyword.name == highlight,
                        textColor: chipTextColor
                    )
                }
            }
        } else if entry.reservesKeywordSpace {
            Color.clear.frame(height: JournalLayout.keywordRowHeight)
        }
    }

    private func highlighted(_ text: String) -> AttributedString {
        var result = AttributedString(text)
        guard let highlight, !highlight.isEmpty else { return result }
        var searchStart = result.startIndex
        while searchStart < result.endIndex,
              let match = result[searchStart...].range(of: highlight, options: .caseInsensitive) {
            result[match].swiftUI.backgroundColor = .HIGHLIGHT_SEARCH
            searchStart = match.upperBound
        }
        return result
    }
}
