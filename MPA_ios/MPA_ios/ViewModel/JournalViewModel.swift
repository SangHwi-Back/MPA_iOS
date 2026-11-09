//
//  JournalViewModel.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/3/26.
//

import Foundation
import SwiftUI

/// An entry removed from the list that can still be restored from the undo toast.
struct JournalDeletion {
    let journal: Journal
    let index: Int
}

struct JournalKeywordSuggestion: Identifiable {
    let name: String
    let count: Int

    var id: String { name }
}

@MainActor
final class JournalViewModel: ObservableObject {

    private static let viewModeKey = "journal.viewMode"
    private static let recentSearchesKey = "journal.recentSearches"
    private static let maxRecentSearches = 5
    private static let maxKeywordSuggestions = 3
    private static let principleStageCount = 5

    @Published var entries: [Journal] = []
    /// The last choice is restored the next time the app opens.
    @Published var viewMode: JournalViewMode = JournalViewModel.storedViewMode() {
        didSet {
            UserDefaults.standard.set(viewMode.rawValue, forKey: Self.viewModeKey)
            if viewMode == .calendar, oldValue != .calendar { selectToday() }
        }
    }
    @Published var searchQuery: String = "" {
        didSet { scheduleSearch() }
    }
    /// `searchQuery` after the 250ms debounce. Results are computed from this value.
    @Published private(set) var appliedSearchQuery: String = ""
    @Published var isSearchActive: Bool = false
    @Published private(set) var recentSearches: [String] =
        UserDefaults.standard.stringArray(forKey: JournalViewModel.recentSearchesKey) ?? []
    @Published var today: Date = Calendar.current.startOfDay(for: .now)
    @Published var selectedDate: Date = Calendar.current.startOfDay(for: .now)
    @Published var displayedMonth: Date = Calendar.current.startOfMonth(for: .now)
    @Published private(set) var pendingDeletion: JournalDeletion?
    /// Incremented when the 기록 tab is tapped again, to scroll back to the top.
    @Published var scrollToTopSignal = 0

    /// Fixes the keyword dot colors to match design images in previews.
    var keywordStageOverride: [String: Int]?

    @Published var productRepository: (any ProductRepositoryProtocol)!

    private var searchTask: Task<Void, Never>?
    private var deletionTask: Task<Void, Never>?

    private static func storedViewMode() -> JournalViewMode {
        UserDefaults.standard.string(forKey: viewModeKey).flatMap(JournalViewMode.init(rawValue:)) ?? .list
    }

    // MARK: - List grouping

    var sortedByMonth: [(month: Date, entries: [Journal])] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: entries) { cal.startOfMonth(for: $0.day) }
        return grouped.keys
            .sorted(by: >)
            .map { m in (m, grouped[m]!.sorted { $0.day > $1.day }) }
    }

    var totalEntriesForMonth: Int {
        let cal = Calendar.current
        return entries.filter { cal.isSameMonth($0.day, as: displayedMonth) }.count
    }

    /// Principle color stage (0 = most recent … 4 = oldest) per keyword, in quintiles of last appearance.
    var keywordStages: [String: Int] {
        if let keywordStageOverride { return keywordStageOverride }
        var lastSeen: [String: Date] = [:]
        for entry in entries {
            for keyword in entry.visibleKeywords {
                lastSeen[keyword.name] = max(lastSeen[keyword.name] ?? entry.day, entry.day)
            }
        }
        let ordered = lastSeen
            .sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }
            .map(\.key)
        var stages: [String: Int] = [:]
        for (index, name) in ordered.enumerated() {
            stages[name] = index * Self.principleStageCount / ordered.count
        }
        return stages
    }

    // MARK: - Search

    var searchKeywordMatches: [JournalKeywordSuggestion] {
        guard !appliedSearchQuery.isEmpty else { return [] }
        let q = appliedSearchQuery.lowercased()
        var counts: [String: Int] = [:]
        for entry in entries {
            for keyword in entry.visibleKeywords where keyword.name.lowercased().contains(q) {
                counts[keyword.name, default: 0] += 1
            }
        }
        return counts
            .sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }
            .prefix(Self.maxKeywordSuggestions)
            .map { JournalKeywordSuggestion(name: $0.key, count: $0.value) }
    }

    var searchTitleBodyMatches: [Journal] {
        guard !appliedSearchQuery.isEmpty else { return [] }
        let q = appliedSearchQuery.lowercased()
        return entries
            .filter { $0.displayTitle.lowercased().contains(q) || $0.body.lowercased().contains(q) }
            .sorted { $0.day > $1.day }
    }

    var hasSearchResults: Bool {
        !appliedSearchQuery.isEmpty && (!searchKeywordMatches.isEmpty || !searchTitleBodyMatches.isEmpty)
    }

    /// Skips the debounce. Used when a recent search is tapped.
    func applySearch(_ query: String) {
        searchTask?.cancel()
        searchQuery = query
        searchTask?.cancel()
        appliedSearchQuery = query
    }

    func commitRecentSearch() {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        storeRecentSearches(Array(([query] + recentSearches.filter { $0 != query }).prefix(Self.maxRecentSearches)))
    }

    func removeRecentSearch(_ query: String) {
        storeRecentSearches(recentSearches.filter { $0 != query })
    }

    private func storeRecentSearches(_ searches: [String]) {
        recentSearches = searches
        UserDefaults.standard.set(searches, forKey: Self.recentSearchesKey)
    }

    private func scheduleSearch() {
        searchTask?.cancel()
        let query = searchQuery
        guard !query.isEmpty else {
            appliedSearchQuery = ""
            return
        }
        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            self?.appliedSearchQuery = query
        }
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

    /// Weekday names ordered by the system's first day of the week.
    var weekdayHeaders: [String] {
        let names = ["일", "월", "화", "수", "목", "금", "토"]
        let first = Calendar.current.firstWeekday - 1
        return Array(names[first...] + names[..<first])
    }

    /// Grid of optional Dates for the displayed month. `nil` is a blank leading or trailing cell.
    var calendarGrid: [Date?] {
        let cal = Calendar.current
        let monthStart = cal.startOfMonth(for: displayedMonth)
        let leading = (cal.component(.weekday, from: monthStart) - cal.firstWeekday + 7) % 7
        let daysInMonth = cal.range(of: .day, in: .month, for: monthStart)!.count
        var grid: [Date?] = Array(repeating: nil, count: leading)
        for d in 0..<daysInMonth {
            grid.append(cal.date(byAdding: .day, value: d, to: monthStart))
        }
        while grid.count % 7 != 0 { grid.append(nil) }
        return grid
    }

    /// Oldest month that can be shown (the month of the first entry).
    var earliestMonth: Date {
        let cal = Calendar.current
        return entries.map(\.day).min().map(cal.startOfMonth(for:)) ?? cal.startOfMonth(for: today)
    }

    var latestMonth: Date { Calendar.current.startOfMonth(for: today) }
    var canGoToPreviousMonth: Bool { displayedMonth > earliestMonth }
    var canGoToNextMonth: Bool { displayedMonth < latestMonth }

    func isFuture(_ date: Date) -> Bool { date > today }

    func selectToday() {
        selectedDate = today
        displayedMonth = Calendar.current.startOfMonth(for: today)
    }

    /// Selects `date`. Returns the entry to open when the selected day is tapped again and holds exactly one entry.
    func selectDay(_ date: Date) -> Journal? {
        let day = Calendar.current.startOfDay(for: date)
        guard !isFuture(day) else { return nil }
        defer { selectedDate = day }
        guard day == selectedDate, selectedDayEntries.count == 1 else { return nil }
        return selectedDayEntries.first
    }

    func changeMonth(by offset: Int) {
        guard (offset < 0 && canGoToPreviousMonth) || (offset > 0 && canGoToNextMonth),
              let month = Calendar.current.date(byAdding: .month, value: offset, to: displayedMonth) else { return }
        showMonth(month)
    }

    /// Shows `month`, clamped to the months that can be browsed, and moves the selection into it.
    func showMonth(_ month: Date) {
        let cal = Calendar.current
        let target = min(max(cal.startOfMonth(for: month), earliestMonth), latestMonth)
        displayedMonth = target
        let latestEntryDay = entries.filter { cal.isSameMonth($0.day, as: target) }.map(\.day).max()
        selectedDate = latestEntryDay ?? (cal.isSameMonth(today, as: target) ? today : target)
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

    /// Removes the entry and shows the undo toast. A previous pending deletion becomes permanent.
    func delete(_ journal: Journal, autoCommit: Bool = true) {
        guard let index = entries.firstIndex(where: { $0.id == journal.id }) else { return }
        commitPendingDeletion()
        entries.remove(at: index)
        pendingDeletion = JournalDeletion(journal: journal, index: index)
        guard autoCommit else { return }

        let isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
        if isVoiceOverRunning {
            UIAccessibility.post(notification: .announcement, argument: "\(journal.displayTitle)을 삭제했어요")
        }
        deletionTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(isVoiceOverRunning ? 10 : 5))
            guard !Task.isCancelled else { return }
            self?.commitPendingDeletion()
        }
    }

    func undoDeletion() {
        guard let deletion = pendingDeletion else { return }
        deletionTask?.cancel()
        entries.insert(deletion.journal, at: min(deletion.index, entries.count))
        pendingDeletion = nil
    }

    /// `entries` is in memory only, so dropping the pending deletion is the hard delete.
    func commitPendingDeletion() {
        deletionTask?.cancel()
        pendingDeletion = nil
    }

    func deactivateSearch() {
        isSearchActive = false
        searchQuery = ""
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

    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? date
    }
}
