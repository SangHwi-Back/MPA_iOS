//
//  JournalHomeView.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/3/26.
//

import SwiftUI

enum JournalViewMode: String, CaseIterable {
    case list
    case calendar

    var title: String {
        switch self {
        case .list:     return "리스트"
        case .calendar: return "캘린더"
        }
    }
}

struct JournalHomeView: View {
    @ObservedObject var viewModel: JournalViewModel
    
    var body: some View {
        VStack {
            JournalHeaderView(onAdd: {})
            JournalSearchBarView(
                query: $viewModel.searchQuery,
                isActive: $viewModel.isSearchActive,
                onCancel: {
                    viewModel.searchQuery = ""
                }
            )
            JournalViewModeToggle(mode: $viewModel.viewMode)
            
            ScrollView {
                switch viewModel.viewMode {
                case .calendar:
                    JournalCalendarView(
                        displayedMonth: .constant(viewModel.displayedMonth),
                        selectedDate: .constant(viewModel.selectedDate),
                        grid: viewModel.calendarGrid,
                        weekdayHeaders: viewModel.weekdayHeaders,
                        entriesByDay: viewModel.entriesByDay,
                        selectedDayEntries: viewModel.selectedDayEntries,
                        onMonthChange: { _ in },
                        onDayTap: { _ in }
                    )
                case .list:
                    if $viewModel.entries.isEmpty {
                        JournalEmptyStateView(onWriteFirst: {})
                    } else {
                        List($viewModel.entries) { entry in
                            JournalEntryRowView(entry: entry.wrappedValue)
                        }
                    }
                }
            }
        }
        .background(Color.CANVAS)
    }
}

private struct JournalHeaderView: View {
    var onAdd: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            Text("기록")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Color.TEXT_PRIMARY)

            Spacer()

            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.BRAND_PRIMARY)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle().fill(Color.SURFACE)
                            .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

private struct JournalSearchBarView: View {
    @Binding var query: String
    @Binding var isActive: Bool
    var onCancel: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.TEXT_TERTIARY)

                if isActive || !query.isEmpty {
                    TextField("제목, 본문, 키워드 검색", text: $query)
                        .focused($isFocused)
                        .font(.body)
                        .submitLabel(.search)
                        .onSubmit {
                            // search is live
                        }

                    if !query.isEmpty {
                        Button {
                            query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.TEXT_TERTIARY)
                                .font(.system(size: 16))
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer(minLength: 0)
                } else {
                    Text("제목, 본문, 키워드 검색")
                        .font(.body)
                        .foregroundStyle(Color.TEXT_TERTIARY)
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.SUNKEN)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.HAIRLINE, lineWidth: 0.5)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                isActive = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isFocused = true
                }
            }

            // Cancel button (only when active)
            if isActive {
                Button("취소") {
                    onCancel()
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.BRAND_PRIMARY)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
}

private struct JournalViewModeToggle: View {
    @Binding var mode: JournalViewMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(JournalViewMode.allCases, id: \.self) { m in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        mode = m
                    }
                } label: {
                    Text(m.title)
                        .font(.subheadline.weight(mode == m ? .semibold : .regular))
                        .foregroundStyle(mode == m ? Color.BRAND_ON_CONTAINER : Color.TEXT_SECONDARY)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .if(mode == m) {
                            $0.background(content: {
                                Capsule().fill(Color.SURFACE)
                                    .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
                            })
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule().fill(Color.SUNKEN)
        )
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
}

/// A small pill: coloured dot + keyword name.
private struct JournalKeywordChipView: View {
    let keyword: JournalKeyword

    /// Deterministic colour from the keyword name (0–4 → principle scale).
    private var dotColor: Color {
        let hash = abs(keyword.name.hashValue) % 5
        let light = LightColorHex.principleScale[hash]
        let dark  = DarkColorHex.principleScale[hash]
        return Color.mpa(light, dark: dark)
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)

            Text(keyword.name)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.TEXT_SECONDARY)

            // Optional "✕" for editor context – not shown in home list
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(Color.SUNKEN)
        )
    }
}

/// One row in the journal list.  Optionally highlights a search keyword.
private struct JournalEntryRowView: View {
    let entry: Journal
    var highlightKeyword: String? = nil
    var showThumbnail: Bool = true

    @Environment(\.colorScheme) private var colorScheme

    private var dayNumber: String {
        String(Calendar.current.component(.day, from: entry.day))
    }

    private var monthLabel: String {
        let m = Calendar.current.component(.month, from: entry.day)
        return "\(m)월"
    }

    private var weekdayLabel: String {
        let wd = ["일", "월", "화", "수", "목", "금", "토"]
        let idx = (Calendar.current.component(.weekday, from: entry.day))
        return wd[(idx - 1) % 7]
    }

    private var keywordChips: [JournalKeyword] {
        Array(entry.visibleKeywords.prefix(Journal.maxKeywordsInList))
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Date column
            HStack(alignment: .top, spacing: 2) {
                Text(dayNumber)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                Text(monthLabel)
                    .font(.caption2)
                    .foregroundStyle(Color.TEXT_TERTIARY)
                    .padding(.top, 4)
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                // Title
                highlightedTitle
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.TEXT_PRIMARY)
                    .lineLimit(1)

                // Snippet
                highlightedSnippet
                    .font(.caption)
                    .foregroundStyle(Color.TEXT_SECONDARY)
                    .lineLimit(2)

                // Keyword chips
                if !keywordChips.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(keywordChips, id: \.name) { kw in
                            JournalKeywordChipView(keyword: kw)
                        }
                    }
                    .padding(.top, 2)
                }
            }
            .layoutPriority(1)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Thumbnail
            if showThumbnail, let thumb = entry.thumbnail {
                JournalThumbnailView(photo: thumb)
                    .padding(.leading, 12)
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    // MARK: - Highlighting

    private var highlightedTitle: Text {
        highlightText(entry.displayTitle, keyword: highlightKeyword)
    }

    private var highlightedSnippet: Text {
        highlightText(entry.previewText, keyword: highlightKeyword)
    }

    private func highlightText(_ source: String, keyword: String?) -> Text {
        guard let keyword, !keyword.isEmpty, source.contains(keyword) else {
            return Text(source)
        }
        var result = Text("")
        let parts = source.components(separatedBy: keyword)
        for (i, part) in parts.enumerated() {
            if i > 0 {
                result = Text(keyword)
//                    .background { Color.HIGHLIGHT_SEARCH.opacity(0.6) }
            }
            if !part.isEmpty {
                result = Text(part)
            }
        }
        return result
    }
}

/// Small rounded image placeholder / photo thumb for a journal entry.
private struct JournalThumbnailView: View {
    let photo: JournalPhoto
    var size: CGFloat = 52

    @State private var uiImage: UIImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.SUNKEN)

            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                // Placeholder: image icon
                Image(systemName: "photo")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.TEXT_TERTIARY)
                .opacity(0.5)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onAppear {
            loadLocalImage()
        }
    }

    private func loadLocalImage() {
        // TODO: resolve fileName → local file URL and load UIImage
        // For preview, stays as placeholder.
    }
}

private struct JournalCalendarView: View {
    @Binding var displayedMonth: Date
    @Binding var selectedDate: Date
    let grid: [Date?]
    let weekdayHeaders: [String]
    let entriesByDay: [Date: [Journal]]
    let selectedDayEntries: [Journal]
    var onMonthChange: (Int) -> Void
    var onDayTap: (Date) -> Void

    private var isToday: (Date) -> Bool {
        { Calendar.current.isDateInToday($0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Month header with arrows
            HStack {
                Text(formattedMonth)
                    .font(.headline)
                    .foregroundStyle(Color.TEXT_PRIMARY)

                Spacer()

                Button { onMonthChange(-1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.TEXT_SECONDARY)

                Spacer().frame(width: 8)

                Button { onMonthChange(1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.TEXT_SECONDARY)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)

            // Weekday header
            HStack(spacing: 0) {
                ForEach(weekdayHeaders, id: \.self) { wd in
                    Text(wd)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.TEXT_TERTIARY)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // Grid
            let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(grid.enumerated()), id: \.offset) { _, date in
                    if let d = date {
                        JournalCalendarDayCell(
                            date: d,
                            isSelected: Calendar.current.isSameMonth(d, as: selectedDate)
                                && Calendar.current.isDate(d, equalTo: selectedDate, toGranularity: .day),
                            isToday: Calendar.current.isDateInToday(d),
                            hasEntry: entriesByDay[Calendar.current.startOfDay(for: d)]?.isEmpty == false
                        )
                        .onTapGesture { onDayTap(d) }
                    } else {
                        Color.clear.frame(height: 36)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)

            Divider().background(Color.HAIRLINE)

            // Selected day detail
            if !selectedDayEntries.isEmpty {
                JournalDayDetailView(
                    date: selectedDate,
                    entries: selectedDayEntries
                )
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
        }
    }

    private var formattedMonth: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy년 M월"
        return f.string(from: displayedMonth)
    }
}

private struct JournalCalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasEntry: Bool

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Selection ring / fill
                if isSelected {
                    Circle()
                        .fill(Color.BRAND_PRIMARY)
                        .frame(width: 36, height: 36)
                } else if isToday {
                    Circle()
                        .stroke(Color.BRAND_PRIMARY, lineWidth: 1.5)
                        .frame(width: 36, height: 36)
                }

                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(
                        isSelected
                        ? Color.BRAND_ON_PRIMARY
                        : (isToday ? Color.BRAND_PRIMARY : Color.TEXT_PRIMARY)
                    )
            }
            .frame(width: 44, height: 36)

            // Dot
            Circle()
                .fill(hasEntry ? Color.BRAND_PRIMARY : Color.clear)
                .frame(width: 4, height: 4)
        }
        .contentShape(Rectangle())
    }
}

private struct JournalDayDetailView: View {
    let date: Date
    let entries: [Journal]

    private var headerText: String {
        let f = DateFormatter()
        f.dateFormat = "M월 d일 E요일"
        // Korean weekday
        let weekday = ["일", "월", "화", "수", "목", "금", "토"]
        let wd = (Calendar.current.component(.weekday, from: date)) - 1
        f.dateFormat = "M월 d일 \(weekday[wd % 7])요일"
        return f.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(headerText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.TEXT_PRIMARY)

            ForEach(entries) { entry in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(String(Calendar.current.component(.day, from: entry.day)))
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.TEXT_PRIMARY)

                        Text(entry.displayTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.TEXT_PRIMARY)
                            .lineLimit(1)
                    }

                    Text(entry.previewText)
                        .font(.caption)
                        .foregroundStyle(Color.TEXT_SECONDARY)
                        .lineLimit(3)

                    if !entry.visibleKeywords.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(Array(entry.visibleKeywords.prefix(3)), id: \.name) { kw in
                                JournalKeywordChipView(keyword: kw)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct JournalEmptyStateView: View {
    var onWriteFirst: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 60)

            // Illustration – use asset "ic_empty_journal" or SF Symbol fallback
            Image("ic_empty_journal")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 100)

            Text("아직 기록이 없어요")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.TEXT_PRIMARY)

            Text("첫 일기를 쓰면 여기에\n날짜별로 자연차곡 모여요.")
                .font(.subheadline)
                .foregroundStyle(Color.TEXT_SECONDARY)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            // CTA
            Button {
                onWriteFirst()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "pencil.and.slash")
                        .font(.subheadline.weight(.medium))
                    Text("첫 일기 쓰기")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(Color.BRAND_ON_CONTAINER)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    Capsule().fill(Color.BRAND_CONTAINER)
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
    }
}

#Preview("JournalHeaderView") {
    JournalHeaderView(onAdd: {})
}

#Preview("Inactive") {
    JournalSearchBarView(query: .constant(""), isActive: .constant(false), onCancel: {})
        .background(Color.CANVAS)
}

#Preview("Active") {
    JournalSearchBarView(query: .constant("경청"), isActive: .constant(true), onCancel: {})
        .background(Color.CANVAS)
}

#Preview("JournalViewModeToggle") {
    JournalViewModeToggle(mode: .constant(.list))
        .background(Color.CANVAS)
}

#Preview("JournalKeywordChipView") {
    HStack(spacing: 8) {
        JournalKeywordChipView(keyword: .init(name: "경청", source: .ai, influence: 0.9))
        JournalKeywordChipView(keyword: .init(name: "솔직함", source: .ai, influence: 0.6))
        JournalKeywordChipView(keyword: .init(name: "꾸준함", source: .user, influence: 1.0))
    }
    .padding()
    .background(Color.CANVAS)
}

#Preview("JournalEntryRowView") {
    JournalEntryRowView(entry: Journal.sample)
        .padding()
        .background(Color.CANVAS)
}

#Preview("JournalThumbnailView") {
    HStack {
        JournalThumbnailView(photo: .init(fileName: "whiteboard.jpg"))
        JournalThumbnailView(photo: .init(fileName: "coffee.jpg"), size: 72)
    }
    .padding()
    .background(Color.CANVAS)
}

#Preview("JournalCalendarView") {
    let vm = JournalViewModel()
    return JournalCalendarView(
        displayedMonth: .constant(vm.displayedMonth),
        selectedDate: .constant(vm.selectedDate),
        grid: vm.calendarGrid,
        weekdayHeaders: vm.weekdayHeaders,
        entriesByDay: vm.entriesByDay,
        selectedDayEntries: vm.selectedDayEntries,
        onMonthChange: { _ in },
        onDayTap: { _ in }
    )
    .background(Color.CANVAS)
    .task {
        await vm.loadSampleData()
    }
}

#Preview("JournalCalendarDayCell") {
    HStack(spacing: 16) {
        JournalCalendarDayCell(date: .now, isSelected: true, isToday: false, hasEntry: true)
        JournalCalendarDayCell(date: .now, isSelected: false, isToday: true, hasEntry: false)
        JournalCalendarDayCell(date: .now, isSelected: false, isToday: false, hasEntry: true)
    }
    .padding()
    .background(Color.CANVAS)
}

#Preview("JournalDayDetailView") {
    JournalDayDetailView(
        date: Calendar.current.date(from: .init(year: 2026, month: 10, day: 27))!,
        entries: [Journal.sample]
    )
    .padding()
    .background(Color.CANVAS)
}

#Preview("JournalEmptyStateView") {
    JournalEmptyStateView(onWriteFirst: {})
        .background(Color.CANVAS)
}

#Preview {
    let vm = JournalViewModel()
    JournalHomeView(viewModel: vm).task {
        await vm.loadSampleData()
    }
}
