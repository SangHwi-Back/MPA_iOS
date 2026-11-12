//
//  [NO AC] Spec: specs/home/SCREEN_SPEC.md
//
//  HomeViewModel.swift
//  MPA_ios
//

import Foundation
import Observation

@Observable
@MainActor
final class HomeViewModel {
    static let principleCount = 5
    static let principleThreshold = 3
    static let recentCount = 5
    static let relatedCount = 3
    static let maxAdviceSources = 3
    static let maxFailures = 3

    // MARK: Inputs

    /// Clock for the greeting, the date line, and "today". Fixed in previews.
    var now: Date
    var entries: [Journal] {
        didSet { if oldValue.map(\.id) != entries.map(\.id) { invalidateForNewEntries() } }
    }
    var aiStatus: HomeAIStatus {
        didSet { if oldValue != aiStatus { resetAI() } }
    }
    var privacyLine: String? {
        switch aiStatus {
        case .unavailable:
            return nil
        case .available(let engine), .keyError(let engine):
            return engine.isOnDevice
                ? "모든 분석은 이 기기 안에서 이루어져요"
                : "요약·키워드만 \(engine == .openAIAPIKey ? "OpenAI" : "Gemini")(내 키)로 전송돼요"
        }
    }

    // MARK: AI cards

    private(set) var advicePhase: HomeAIPhase
    private(set) var promptPhase: HomeAIPhase
    private(set) var writingPrompt: String?
    private(set) var summaryPhase: HomeAIPhase
    /// True only while a freshly generated advice is revealed word by word.
    private(set) var revealsAdviceByWord = false
    var isSummaryExpanded = false
    var isAlertPresented = false

    /// Week strip paging (0 = this week, -1 = last week …). Swiping right goes back.
    var weekOffset = 0

    private var adviceFailures = 0
    private var summaryFailures = 0
    private let generator: any HomeAIGenerating
    private let calendar: Calendar

    init(
        entries: [Journal] = [],
        aiStatus: HomeAIStatus = .available(.appleIntelligence),
        now: Date = .now,
        generator: any HomeAIGenerating = StubHomeAIGenerator(),
        advice: AIText? = nil,
        writingPrompt: String? = nil,
        weeklySummary: AIText? = nil,
        isSummaryExpanded: Bool = false,
        isAlertPresented: Bool = false,
        calendar: Calendar = .current
    ) {
        self.entries = entries
        self.aiStatus = aiStatus
        self.now = now
        self.generator = generator
        self.calendar = calendar
        self.advicePhase = advice.map(HomeAIPhase.loaded) ?? .idle
        self.writingPrompt = writingPrompt
        self.promptPhase = writingPrompt == nil ? .idle : .loaded(AIText(
            text: writingPrompt!, engine: aiStatus.engine ?? .appleIntelligence,
            generatedAt: now, sourceJournalIDs: [], feedback: nil
        ))
        self.summaryPhase = weeklySummary.map(HomeAIPhase.loaded) ?? .idle
        self.isSummaryExpanded = isSummaryExpanded
        self.isAlertPresented = isAlertPresented
    }

    // MARK: - Derived state

    var today: Date { calendar.startOfDay(for: now) }

    var layout: HomeLayout { Self.layout(entryCount: entries.count, isAIAvailable: aiStatus.isAvailable) }

    var greeting: String {
        Self.greeting(hour: calendar.component(.hour, from: now), isFirstRun: entries.isEmpty)
    }

    var dateLine: String { Self.dateLine(now) }

    /// The latest entry written for today, if any.
    var todayEntry: Journal? {
        entries
            .filter { calendar.isDate($0.day, inSameDayAs: today) }
            .max { $0.createdAt < $1.createdAt }
    }

    var principles: [HomePrinciple] { Self.principles(in: entries) }

    var weekDays: [HomeWeekDay] {
        Self.weekDays(containing: today, offset: weekOffset, entries: entries, calendar: calendar)
    }

    var recentEntries: [Journal] { Array(Self.newestFirst(entries).prefix(Self.recentCount)) }

    var thisWeekEntries: [Journal] {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: today) else { return [] }
        return entries.filter { week.contains($0.day) }
    }

    /// 3.11: hidden with no entries this week or fewer than 3 entries overall.
    var showsWeeklySummary: Bool {
        aiStatus.isAvailable && entries.count >= Self.principleThreshold && !thisWeekEntries.isEmpty
    }

    /// "10월 26일–30일 · 일기 4개".
    var weeklyRangeLine: String {
        let days = thisWeekEntries.map(\.day)
        guard let first = days.min(), let last = days.max() else { return "" }
        return Self.rangeText(from: first, to: last, calendar: calendar) + " · 일기 \(thisWeekEntries.count)개"
    }

    /// Entries a text was based on, oldest first (3.4).
    func sources(of text: AIText) -> [Journal] {
        text.sourceJournalIDs
            .compactMap { id in entries.first { $0.id == id } }
            .sorted { $0.day < $1.day }
    }

    /// The entries the next advice is based on: newest 1–3, so 1–2 entries give that many chips.
    var adviceSourceIDs: [UUID] {
        Self.newestFirst(entries).prefix(Self.maxAdviceSources).map(\.id)
    }

    /// 3.3 / Part B 7: the local check runs on the entries the advice would read.
    var isSensitive: Bool {
        Self.newestFirst(entries).prefix(Self.maxAdviceSources)
            .contains { JournalSensitiveContent.isSensitive($0.title + " " + $0.body) }
    }

    // MARK: - Loading

    /// Starts every AI card the current layout shows that has nothing yet.
    func load() async {
        guard aiStatus.isAvailable, !entries.isEmpty else { return }
        async let advice: Void = loadAdviceIfNeeded()
        async let prompt: Void = loadPromptIfNeeded()
        async let summary: Void = loadSummaryIfNeeded()
        _ = await (advice, prompt, summary)
    }

    private func loadAdviceIfNeeded() async {
        guard advicePhase == .idle else { return }
        await generateAdvice()
    }

    private func loadPromptIfNeeded() async {
        guard todayEntry == nil, promptPhase == .idle else { return }
        await nextPrompt()
    }

    private func loadSummaryIfNeeded() async {
        guard showsWeeklySummary, summaryPhase == .idle else { return }
        await generateSummary()
    }

    func generateAdvice() async {
        if isSensitive { advicePhase = .sensitive; return }
        guard let engine = aiStatus.engine else { return }
        if case .keyError = aiStatus { advicePhase = .keyError; return }
        advicePhase = .loading
        do {
            let text = try await generator.advice(
                sourceIDs: adviceSourceIDs,
                isShort: entries.count < Self.principleThreshold,
                engine: engine
            )
            adviceFailures = 0
            revealsAdviceByWord = true
            advicePhase = .loaded(text)
        } catch {
            adviceFailures += 1
            advicePhase = adviceFailures >= Self.maxFailures ? .resting : .failed
        }
    }

    /// ↻: back to the loading state, then a new advice (3.5).
    func regenerateAdvice() async {
        await generateAdvice()
    }

    /// Fills the chosen thumb; tapping it again clears it (Part B 3).
    func toggleFeedback(_ feedback: AIFeedback) {
        guard case .loaded(var text) = advicePhase else { return }
        text.feedback = text.feedback == feedback ? nil : feedback
        revealsAdviceByWord = false
        advicePhase = .loaded(text)
    }

    /// "다른 질문": only the question is regenerated (3.6).
    func nextPrompt() async {
        guard let engine = aiStatus.engine else { return }
        promptPhase = .loading
        do {
            let prompt = try await generator.writingPrompt(engine: engine)
            writingPrompt = prompt
            promptPhase = .loaded(AIText(text: prompt, engine: engine, generatedAt: .now, sourceJournalIDs: [], feedback: nil))
        } catch {
            promptPhase = writingPrompt == nil ? .failed : promptPhase
        }
    }

    func generateSummary() async {
        guard let engine = aiStatus.engine else { return }
        if case .keyError = aiStatus { summaryPhase = .keyError; return }
        summaryPhase = .loading
        do {
            let text = try await generator.weeklySummary(sourceIDs: thisWeekEntries.map(\.id), engine: engine)
            summaryFailures = 0
            summaryPhase = .loaded(text)
        } catch {
            summaryFailures += 1
            summaryPhase = summaryFailures >= Self.maxFailures ? .resting : .failed
        }
    }

    private func resetAI() {
        advicePhase = .idle
        promptPhase = .idle
        summaryPhase = .idle
        writingPrompt = nil
        adviceFailures = 0
        summaryFailures = 0
    }

    private func invalidateForNewEntries() {
        // New entries change the sources and the progress state, so the advice is written again.
        if case .loaded = advicePhase { advicePhase = .idle }
        if case .sensitive = advicePhase { advicePhase = .idle }
        if case .loaded = summaryPhase { summaryPhase = .idle }
    }

    // MARK: - Pure helpers

    static func layout(entryCount: Int, isAIAvailable: Bool) -> HomeLayout {
        if entryCount == 0 { return .firstRun }
        if !isAIAvailable { return .diary }
        return entryCount < principleThreshold ? .early : .full
    }

    /// 아침 5–11시 / 오후 12–17시 / 저녁 18–21시 / 밤. First run always says "반가워요".
    static func greeting(hour: Int, isFirstRun: Bool) -> String {
        if isFirstRun { return "반가워요" }
        switch hour {
        case 5..<12: return "좋은 아침이에요"
        case 12..<18: return "좋은 오후예요"
        case 18..<22: return "좋은 저녁이에요"
        default: return "편안한 밤이에요"
        }
    }

    /// "10월 30일 금요일" (follows the locale).
    static func dateLine(_ date: Date, locale: Locale = Locale(identifier: "ko_KR")) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("MMMMdEEEE")
        return formatter.string(from: date)
    }

    /// "10월 20일" for source chips.
    static func chipDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: date)
    }

    /// "오전 8:12".
    static func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h:mm"
        return formatter.string(from: date)
    }

    /// "10월 26일–30일", or "10월 30일–11월 1일" across months.
    static func rangeText(from start: Date, to end: Date, calendar: Calendar = .current) -> String {
        let startText = chipDate(start)
        if calendar.isDate(start, inSameDayAs: end) { return startText }
        let sameMonth = calendar.component(.month, from: start) == calendar.component(.month, from: end)
        let endText = sameMonth ? "\(calendar.component(.day, from: end))일" : chipDate(end)
        return "\(startText)–\(endText)"
    }

    static func newestFirst(_ entries: [Journal]) -> [Journal] {
        entries.sorted { $0.day == $1.day ? $0.createdAt > $1.createdAt : $0.day > $1.day }
    }

    /// Top 5 keywords by entry count (ties: most recent first). Stages rank the 5 by last appearance.
    static func principles(in entries: [Journal]) -> [HomePrinciple] {
        let names = JournalDetailViewModel.topPrinciples(in: entries)
        let lastSeen: [String: Date] = Dictionary(uniqueKeysWithValues: names.map { name in
            (name, entries.filter { $0.visibleKeywords.contains { $0.name == name } }.map(\.day).max() ?? .distantPast)
        })
        let byRecency = names.sorted { lastSeen[$0]! > lastSeen[$1]! }
        return names.map { name in
            let matching = entries.compactMap { entry -> (Journal, Double)? in
                guard let keyword = entry.visibleKeywords.first(where: { $0.name == name }) else { return nil }
                return (entry, keyword.influence)
            }
            let related = matching
                .sorted { $0.1 == $1.1 ? $0.0.day > $1.0.day : $0.1 > $1.1 }
                .prefix(relatedCount)
                .map(\.0)
            return HomePrinciple(
                name: name,
                count: matching.count,
                stage: byRecency.firstIndex(of: name) ?? 0,
                related: Array(related)
            )
        }
    }

    /// Monday-first week containing `today`, shifted by `offset` weeks.
    static func weekDays(containing today: Date, offset: Int, entries: [Journal], calendar: Calendar = .current) -> [HomeWeekDay] {
        var mondayCalendar = calendar
        mondayCalendar.firstWeekday = 2
        guard
            let shifted = mondayCalendar.date(byAdding: .weekOfYear, value: offset, to: today),
            let week = mondayCalendar.dateInterval(of: .weekOfYear, for: shifted)
        else { return [] }
        let entryDays = Set(entries.map { calendar.startOfDay(for: $0.day) })
        return (0..<7).compactMap { index in
            guard let date = mondayCalendar.date(byAdding: .day, value: index, to: week.start) else { return nil }
            let day = calendar.startOfDay(for: date)
            return HomeWeekDay(
                date: day,
                hasEntry: entryDays.contains(day),
                isToday: calendar.isDate(day, inSameDayAs: today),
                isFuture: day > today
            )
        }
    }
}
