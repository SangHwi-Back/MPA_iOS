//
//  JournalViewModel.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/3/26.
//

import Foundation
import SwiftUI

@MainActor
final class JournalViewModel: ObservableObject {
    
    @Published var entries: [Journal] = []
    @Published var viewMode: JournalViewMode = .list
    @Published var searchQuery: String = ""
    @Published var isSearchActive: Bool = false
    @Published var selectedDate: Date = Calendar.current.startOfDay(for: .now)
    @Published var displayedMonth: Date = {
        Calendar.current.date(from: DateComponents(calendar: .current, day: 1)) ?? .now
    }()
    
    @Published var productRepository: (any ProductRepositoryProtocol)!
    
    // MARK: - List grouping
    
    var sortedByMonth: [(month: Date, entries: [Journal])] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: entries) {
            cal.date(from: cal.dateComponents([.year, .month], from: $0.day)) ?? $0.day
        }
        return grouped.keys
            .sorted(by: >)
            .map { m in
                (m, grouped[m]!.filter { cal.isSameMonth($0.day, as: m) }.sorted { $0.day > $1.day })
            }
    }
    
    var totalEntriesForMonth: Int {
        let cal = Calendar.current
        return entries.filter { cal.isSameMonth($0.day, as: displayedMonth) }.count
    }
    
    // MARK: - Search
    
    var searchKeywordMatches: [JournalKeyword] {
        guard !searchQuery.isEmpty else { return [] }
        let q = searchQuery.lowercased()
        var seen = Set<String>()
        return entries
            .flatMap { $0.keywords.filter { !$0.isExcluded } }
            .filter { seen.insert($0.name).inserted }
            .filter { $0.name.lowercased().contains(q) }
    }
    
    var searchTitleBodyMatches: [Journal] {
        guard !searchQuery.isEmpty else { return [] }
        let q = searchQuery.lowercased()
        return entries
            .filter { $0.displayTitle.lowercased().contains(q) || $0.body.lowercased().contains(q) }
            .sorted { $0.day > $1.day }
    }
    
    var hasSearchResults: Bool {
        !searchQuery.isEmpty && (!searchKeywordMatches.isEmpty || !searchTitleBodyMatches.isEmpty)
    }
    
    // MARK: - Calendar
    
    var entriesByDay: [Date: [Journal]] {
        var dict: [Date: [Journal]] = [:]
        for e in entries { dict[e.day, default: []].append(e) }
        for k in dict.keys { dict[k]?.sort { $0.createdAt > $1.createdAt } }
        return dict
    }
    
    var selectedDayEntries: [Journal] {
        entriesByDay[Calendar.current.startOfDay(for: selectedDate)] ?? []
    }
    
    /// Weekday names: 일 월 화 수 목 금 토
    var weekdayHeaders: [String] { ["일", "월", "화", "수", "목", "금", "토"] }
    
    /// 6 × 7 grid of optional Dates for the displayed month.
    var calendarGrid: [Date?] {
        let cal = Calendar.current
        let monthStart = date(from: displayedMonth)
        guard let monthStart else { return [] }
        let firstWeekday = cal.component(.weekday, from: monthStart) // 1 = Sun
        let daysInMonth = cal.range(of: .day, in: .month, for: displayedMonth)!.count
        var grid: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        for d in 1...daysInMonth {
            var dc = cal.dateComponents([.year, .month], from: displayedMonth)
            dc.day = d
            grid.append(cal.date(from: dc))
        }
        while grid.count % 7 != 0 { grid.append(nil) }
        return grid
    }
    
    private func date(from componentDate: Date) -> Date? {
        let cal = Calendar.current
        var dc = cal.dateComponents([.year, .month], from: componentDate)
        dc.day = 1
        return cal.date(from: dc)
    }
    
    // MARK: - Mutations
    
    /// Creates a new journal entry and appends it to `entries`. There is no server/DB yet,
    /// so this is the only source of truth for journals across the app.
    @discardableResult
    func addJournal(
        day: Date = Calendar.current.startOfDay(for: .now),
        title: String = "",
        body: String = "",
        prompt: String? = nil
    ) -> Journal {
        let journal = Journal(day: day, title: title, body: body, prompt: prompt)
        entries.append(journal)
        return journal
    }
    
    func deactivateSearch() {
        isSearchActive = false
        searchQuery = ""
    }
    
    func changeMonth(by offset: Int) {
        var dc = Calendar.current.dateComponents([.year, .month], from: displayedMonth)
        dc.month = dc.month!.addingMonths(offset)
        displayedMonth = Calendar.current.date(from: dc) ?? displayedMonth
    }
    
    /// Load sample data for preview.
    func loadSampleData() {
        entries = [Journal.sample]
    }
}

// MARK: - Date helpers

extension Calendar {
    func isSameMonth(_ lhs: Date, as rhs: Date) -> Bool {
        let a = dateComponents([.year, .month], from: lhs)
        let b = dateComponents([.year, .month], from: rhs)
        return a.year == b.year && a.month == b.month
    }
}

extension Int {
    func addingMonths(_ delta: Int) -> Int { self + delta }
}
