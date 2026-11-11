//
//  [NO AC] Spec: specs/home/SCREEN_SPEC.md
//
//  HomeSidebarView.swift
//  MPA_ios
//
//  Tablet sidebar of 오늘: recent entries, or a month calendar after the calendar button.
//  Keeps its own month and selection so it does not move the 기록 tab's calendar.
//

import SwiftUI

struct HomeSidebarView: View {
    @Environment(JournalViewModel.self) private var viewModel
    let today: Date
    let onOpen: (Journal) -> Void
    let onSeeAll: () -> Void

    @State private var isCalendarMode: Bool
    @State private var displayedMonth: Date
    @State private var selectedDay: Date

    private let calendar = Calendar.current

    init(
        today: Date,
        isCalendarMode: Bool = false,
        selectedDay: Date? = nil,
        onOpen: @escaping (Journal) -> Void,
        onSeeAll: @escaping () -> Void
    ) {
        self.today = today
        self.onOpen = onOpen
        self.onSeeAll = onSeeAll
        let day = Calendar.current.startOfDay(for: selectedDay ?? today)
        self._isCalendarMode = State(initialValue: isCalendarMode)
        self._selectedDay = State(initialValue: day)
        self._displayedMonth = State(initialValue: Calendar.current.startOfMonth(for: day))
    }

//    private var entries: [Journal] { HomeViewModel.newestFirst(viewModel.entries) }
    private var entries: [Journal] {
        viewModel.entries
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isCalendarMode {
                    calendarContent
                } else {
                    recentContent
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color.SUNKEN.opacity(0.5))
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { isCalendarMode.toggle() }
                } label: {
                    Image(systemName: "calendar")
                        .foregroundStyle(isCalendarMode ? Color.BRAND_PRIMARY : Color.TEXT_PRIMARY)
                }
                .buttonStyle(.borderedProminent)
                .tint(isCalendarMode ? Color.BRAND_CONTAINER : Color.SURFACE)
                .accessibilityLabel(isCalendarMode ? "최근 기록 보기" : "캘린더 보기")
            }
        }
        .toolbar(removing: .sidebarToggle)
    }

    // MARK: Recent

    @ViewBuilder
    private var recentContent: some View {
        HomeSectionHeader(title: "최근 기록", actionTitle: "모두 보기", action: onSeeAll)
            .padding(.horizontal, 8)
        if entries.isEmpty {
            Text("아직 기록이 없어요")
                .font(.system(size: 15))
                .foregroundStyle(Color.TEXT_SECONDARY)
                .padding(.horizontal, 8)
        } else {
            Text(monthTitle(entries[0].day))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.TEXT_SECONDARY)
                .padding(.horizontal, 8)
            ForEach(entries, id: \.id) { entry in
                Button { onOpen(entry) } label: {
                    HomeRecentRow(entry: entry, isHighlighted: calendar.isDate(entry.day, inSameDayAs: today))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, calendar.isDate(entry.day, inSameDayAs: today) ? 0 : 8)
            }
        }
    }

    // MARK: Calendar

    @ViewBuilder
    private var calendarContent: some View {
        HStack {
            Text(monthTitle(displayedMonth))
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.TEXT_PRIMARY)
            Spacer()
            Button { shiftMonth(-1) } label: { Image(systemName: "chevron.left") }
                .disabled(!canGoBack)
                .frame(width: 44, height: 44)
            Button { shiftMonth(1) } label: { Image(systemName: "chevron.right") }
                .disabled(!canGoForward)
                .frame(width: 44, height: 44)
        }
        .foregroundStyle(Color.BRAND_PRIMARY)

        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 6) {
            ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { name in
                Text(name)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.TEXT_SECONDARY)
                    .frame(height: 32)
            }
            ForEach(Array(grid.enumerated()), id: \.offset) { _, date in
                if let date {
                    dayCell(date)
                } else {
                    Color.clear.frame(height: 44)
                }
            }
        }

        Text(HomeViewModel.dateLine(selectedDay))
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color.TEXT_SECONDARY)
            .padding(.top, 8)
        ForEach(dayEntries, id: \.id) { entry in
            Button { onOpen(entry) } label: { selectedDayRow(entry) }
                .buttonStyle(.plain)
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDay)
        let isToday = calendar.isDate(date, inSameDayAs: today)
        let hasEntry = viewModel.entries.contains { calendar.isDate($0.day, inSameDayAs: date) }
        let isFuture = date > today
        return Button {
            selectedDay = date
        } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 17, weight: isSelected || isToday ? .bold : .regular))
                Circle()
                    .fill(hasEntry ? (isSelected ? Color.BRAND_ON_PRIMARY : Color.BRAND_PRIMARY) : .clear)
                    .frame(width: 5, height: 5)
            }
            .foregroundStyle(isSelected ? Color.BRAND_ON_PRIMARY : (isFuture ? Color.TEXT_TERTIARY : (isToday ? Color.BRAND_PRIMARY : Color.TEXT_PRIMARY)))
            .frame(width: 44, height: 44)
            .background { if isSelected { Circle().fill(Color.BRAND_PRIMARY) } }
            .overlay { if isToday && !isSelected { Circle().stroke(Color.BRAND_PRIMARY, lineWidth: 1.5) } }
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
    }

    private func selectedDayRow(_ entry: Journal) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HomeRecentRow(entry: entry)
            let keywords = entry.visibleKeywords.prefix(Journal.maxKeywordsInList)
            if !keywords.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Array(keywords), id: \.name) { keyword in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(homePrincipleColor(stage: viewModel.keywordStages[keyword.name] ?? 0))
                                .frame(width: 8, height: 8)
                            Text(keyword.name)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.TEXT_PRIMARY)
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 30)
                        .background(Color.AI_TINT, in: Capsule())
                    }
                }
                .padding(.leading, 60)
                .padding(.bottom, 8)
            }
        }
        .padding(.horizontal, 12)
        .background(Color.SURFACE, in: .rect(cornerRadius: 20, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.HAIRLINE, lineWidth: 1) }
    }

    // MARK: Helpers

    private var dayEntries: [Journal] {
        entries.filter { calendar.isDate($0.day, inSameDayAs: selectedDay) }
    }

    private var grid: [Date?] {
        let leading = (calendar.component(.weekday, from: displayedMonth) - 1 + 7) % 7
        let count = calendar.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for offset in 0..<count {
            cells.append(calendar.date(byAdding: .day, value: offset, to: displayedMonth))
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }

    private var canGoBack: Bool {
//        guard let first = viewModel.entries.map(\.day).min() else { return false }
//        return displayedMonth > calendar.startOfMonth(for: first)
        return true
    }

    private var canGoForward: Bool { displayedMonth < calendar.startOfMonth(for: today) }

    private func shiftMonth(_ delta: Int) {
        if let month = calendar.date(byAdding: .month, value: delta, to: displayedMonth) {
            displayedMonth = month
        }
    }

    private func monthTitle(_ date: Date) -> String {
        "\(calendar.component(.year, from: date))년 \(calendar.component(.month, from: date))월"
    }
}
