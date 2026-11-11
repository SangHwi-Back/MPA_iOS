//
//  JournalCalendarSection.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/11/26.
//

import SwiftUI

struct JournalCalendarSection: View {
    @Bindable var viewModel: JournalViewModel
    let keywordStages: [String: Int]
    let onOpenEntry: (Journal) -> Void
    let onWrite: (Date) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        let entriesByDay = viewModel.entriesByDay
        VStack(alignment: .leading, spacing: 0) {
            JournalMonthPicker(viewModel: viewModel)

            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(viewModel.weekdayHeaders, id: \.self) { name in
                    Text(name)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.TEXT_SECONDARY)
                        .frame(height: 30)
                }
                ForEach(Array(viewModel.calendarGrid.enumerated()), id: \.offset) { _, date in
                    if let date {
                        dayCell(date, hasEntry: entriesByDay[date]?.isEmpty == false)
                    } else {
                        Color.clear.frame(height: 46)
                    }
                }
            }
            .monthSwipe(viewModel)

            Rectangle()
                .fill(Color.HAIRLINE)
                .frame(height: 1)
                .padding(.top, 8)

            dayContent
                .padding(.top, 14)
        }
    }

    private func dayCell(_ date: Date, hasEntry: Bool) -> some View {
        let isSelected = date == viewModel.selectedDate
        let isFuture = viewModel.isFuture(date)
        return Button {
            if let entry = viewModel.selectDay(date) { onOpenEntry(entry) }
        } label: {
            JournalCalendarDayCell(
                date: date,
                isSelected: isSelected,
                isToday: date == viewModel.today,
                isFuture: isFuture,
                hasEntry: hasEntry
            )
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .accessibilityLabel(journalDayAccessibilityLabel(date, hasEntry: hasEntry, isSelected: isSelected))
    }

    @ViewBuilder
    private var dayContent: some View {
        if viewModel.totalEntriesForMonth == 0 {
            JournalMonthEmptyView()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text(JournalDateText.selectedDay(viewModel.selectedDate))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.TEXT_SECONDARY)

                if viewModel.selectedDayEntries.isEmpty {
                    JournalDayEmptyView { onWrite(viewModel.selectedDate) }
                } else {
                    ForEach(viewModel.selectedDayEntries) { entry in
                        JournalEntryRow(entry: entry, keywordStages: keywordStages)
                            .contentShape(Rectangle())
                            .onTapGesture { onOpenEntry(entry) }
                    }
                }
            }
        }
    }
}

// MARK: - Calendar (phone)

private struct JournalMonthPicker: View {
    @Bindable var viewModel: JournalViewModel
    @State private var isShowingPicker = false

    private var pickerSelection: Binding<Date> {
        Binding(get: { viewModel.displayedMonth }, set: { viewModel.showMonth($0) })
    }

    var body: some View {
        HStack(spacing: 0) {
            Button {
                isShowingPicker = true
            } label: {
                Text(JournalDateText.yearMonth(viewModel.displayedMonth))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.TEXT_PRIMARY)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $isShowingPicker) {
                DatePicker(
                    "연·월 선택",
                    selection: pickerSelection,
                    in: viewModel.earliestMonth...viewModel.today,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()
                .presentationCompactAdaptation(.popover)
            }

            Spacer(minLength: 0)

            arrow("chevron.left", label: "이전 달", isEnabled: viewModel.canGoToPreviousMonth) {
                viewModel.changeMonth(by: -1)
            }
            arrow("chevron.right", label: "다음 달", isEnabled: viewModel.canGoToNextMonth) {
                viewModel.changeMonth(by: 1)
            }
        }
    }

    private func arrow(_ symbol: String, label: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(isEnabled ? Color.BRAND_PRIMARY : Color.DISABLE)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(label)
    }
}

// MARK: - Calendar (tablet)

struct JournalTabletCalendar: View {
    @Bindable var viewModel: JournalViewModel
    let keywordStages: [String: Int]
    let onOpenEntry: (Journal) -> Void
    let onWrite: (Date) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        HStack(alignment: .top, spacing: 30) {
            calendar
            selectedDayPanel.frame(width: 370)
        }
    }

    private var calendar: some View {
        let entriesByDay = viewModel.entriesByDay
        return VStack(alignment: .leading, spacing: 8) {
            JournalMonthPicker(viewModel: viewModel)

            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(viewModel.weekdayHeaders, id: \.self) { name in
                    Text(name)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.TEXT_SECONDARY)
                        .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
                        .padding(.leading, 4)
                }
                ForEach(Array(viewModel.calendarGrid.enumerated()), id: \.offset) { _, date in
                    if let date {
                        dayCell(date, entries: entriesByDay[date] ?? [])
                    } else {
                        Color.clear
                            .frame(height: 84)
                            .overlay(alignment: .top) { hairline }
                    }
                }
            }
            .monthSwipe(viewModel)
        }
        .frame(maxWidth: .infinity)
    }

    private var hairline: some View {
        Rectangle().fill(Color.HAIRLINE).frame(height: 1)
    }

    private func dayCell(_ date: Date, entries: [Journal]) -> some View {
        let isSelected = date == viewModel.selectedDate
        let isToday = date == viewModel.today
        let isFuture = viewModel.isFuture(date)
        return Button {
            if let entry = viewModel.selectDay(date) { onOpenEntry(entry) }
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(JournalDateText.day(date))
                    .font(.system(size: 14, weight: isSelected || isToday ? .bold : .regular))
                    .foregroundStyle(isSelected ? Color.BRAND_ON_PRIMARY : isFuture ? Color.DISABLE : isToday ? Color.BRAND_PRIMARY : Color.TEXT_PRIMARY)
                    .frame(width: 26, height: 26)
                    .background {
                        if isSelected {
                            Circle().fill(Color.BRAND_PRIMARY)
                        } else if isToday {
                            Circle().stroke(Color.BRAND_PRIMARY, lineWidth: 1.5)
                        }
                    }
                if let entry = entries.first {
                    Text(entry.displayTitle)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.TEXT_SECONDARY)
                        .lineLimit(1)
                        .padding(.horizontal, 6)
                        .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.AI_TINT))
                }
                Spacer(minLength: 0)
            }
            .padding(4)
            .frame(maxWidth: .infinity, minHeight: 84, maxHeight: 84, alignment: .topLeading)
            .background(isSelected ? Color.SUNKEN.opacity(0.7) : Color.clear)
            .overlay(alignment: .top) { hairline }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .accessibilityLabel(journalDayAccessibilityLabel(date, hasEntry: !entries.isEmpty, isSelected: isSelected))
    }

    @ViewBuilder
    private var selectedDayPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(JournalDateText.selectedDay(viewModel.selectedDate))
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.TEXT_PRIMARY)

            if viewModel.totalEntriesForMonth == 0 {
                JournalMonthEmptyView()
            } else if viewModel.selectedDayEntries.isEmpty {
                JournalDayEmptyView { onWrite(viewModel.selectedDate) }
            } else {
                ForEach(viewModel.selectedDayEntries) { entry in
                    entryCard(entry)
                }
            }
        }
        .padding(.top, 6)
    }

    private func entryCard(_ entry: Journal) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if entry.thumbnail != nil {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.PLACEHOLDER)
                    .frame(height: 144)
            }
            Text(entry.displayTitle)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.TEXT_PRIMARY)
                .padding(.top, 8)
            Text(entry.previewText)
                .font(.system(size: 15))
                .foregroundStyle(Color.TEXT_PRIMARY.opacity(0.8))
                .lineSpacing(6)
            if entry.showsKeywords {
                HStack(spacing: 6) {
                    ForEach(Array(entry.visibleKeywords.prefix(Journal.maxKeywordsInList)), id: \.name) { keyword in
                        JournalKeywordChip(
                            name: keyword.name,
                            stage: keywordStages[keyword.name] ?? 0,
                            textColor: .TEXT_SECONDARY
                        )
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.SURFACE))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.HAIRLINE, lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture { onOpenEntry(entry) }
    }
}

private struct JournalCalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isFuture: Bool
    let hasEntry: Bool

    private var numberColor: Color {
        if isSelected { return .BRAND_ON_PRIMARY }
        if isFuture { return .DISABLE }
        return isToday ? .BRAND_PRIMARY : .TEXT_PRIMARY
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(JournalDateText.day(date))
                .font(.system(size: 16, weight: isSelected || isToday ? .bold : .regular))
                .foregroundStyle(numberColor)
                .frame(width: 34, height: 34)
                .background {
                    if isSelected {
                        Circle().fill(Color.BRAND_PRIMARY)
                    } else if isToday {
                        Circle().stroke(Color.BRAND_PRIMARY, lineWidth: 1.5)
                    }
                }
            Circle()
                .fill(hasEntry ? Color.BRAND_PRIMARY : Color.clear)
                .frame(width: 5, height: 5)
        }
        .frame(maxWidth: .infinity, minHeight: 46)
        .contentShape(Rectangle())
    }
}

private func journalDayAccessibilityLabel(_ date: Date, hasEntry: Bool, isSelected: Bool) -> String {
    var parts = ["\(JournalDateText.month(date)) \(JournalDateText.day(date))일"]
    if hasEntry { parts.append("일기 있음") }
    if isSelected { parts.append("선택됨") }
    return parts.joined(separator: ", ")
}

private extension View {
    /// Moves between months with a horizontal swipe.
    func monthSwipe(_ viewModel: JournalViewModel) -> some View {
        simultaneousGesture(
            DragGesture(minimumDistance: 30).onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) * 2 else { return }
                viewModel.changeMonth(by: value.translation.width < 0 ? 1 : -1)
            }
        )
    }
}
