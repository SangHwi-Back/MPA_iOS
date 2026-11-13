//
//  [NO AC] Spec: specs/home/SCREEN_SPEC.md
//
//  HomeViewModelTests.swift
//  MPA_iosTests
//

import XCTest
@testable import MPA_ios

private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0) -> Date {
    Calendar.current.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
}

private func oct(_ d: Int) -> Date { date(2026, 10, d) }

private let homeNow = date(2026, 10, 30, 8, 0)

private func homeJournal(_ day: Date, keywords: [(String, Double)] = [], body: String = "") -> Journal {
    Journal(day: day, createdAt: day, body: body, keywords: keywords.map { JournalKeyword(name: $0.0, source: .ai, influence: $0.1) })
}

@MainActor
final class HomeViewModelTests: XCTestCase {

    // MARK: - Layout and text

    func testLayoutFollowsStateMatrix() {
        XCTAssertEqual(HomeViewModel.layout(entryCount: 0, isAIAvailable: true), .firstRun)
        XCTAssertEqual(HomeViewModel.layout(entryCount: 0, isAIAvailable: false), .firstRun)
        XCTAssertEqual(HomeViewModel.layout(entryCount: 3, isAIAvailable: false), .diary)
        XCTAssertEqual(HomeViewModel.layout(entryCount: 2, isAIAvailable: true), .early)
        XCTAssertEqual(HomeViewModel.layout(entryCount: 3, isAIAvailable: true), .full)
    }

    func testGreetingBoundaries() {
        XCTAssertEqual(HomeViewModel.greeting(hour: 12, isFirstRun: true), "반가워요")
        XCTAssertEqual(HomeViewModel.greeting(hour: 4, isFirstRun: false), "편안한 밤이에요")
        XCTAssertEqual(HomeViewModel.greeting(hour: 5, isFirstRun: false), "좋은 아침이에요")
        XCTAssertEqual(HomeViewModel.greeting(hour: 11, isFirstRun: false), "좋은 아침이에요")
        XCTAssertEqual(HomeViewModel.greeting(hour: 12, isFirstRun: false), "좋은 오후예요")
        XCTAssertEqual(HomeViewModel.greeting(hour: 17, isFirstRun: false), "좋은 오후예요")
        XCTAssertEqual(HomeViewModel.greeting(hour: 18, isFirstRun: false), "좋은 저녁이에요")
        XCTAssertEqual(HomeViewModel.greeting(hour: 21, isFirstRun: false), "좋은 저녁이에요")
        XCTAssertEqual(HomeViewModel.greeting(hour: 22, isFirstRun: false), "편안한 밤이에요")
    }

    func testDateTexts() {
        XCTAssertEqual(HomeViewModel.dateLine(oct(30)), "10월 30일 금요일")
        XCTAssertEqual(HomeViewModel.rangeText(from: oct(26), to: oct(30)), "10월 26일–30일")
        XCTAssertEqual(HomeViewModel.rangeText(from: oct(30), to: date(2026, 11, 1)), "10월 30일–11월 1일")
        XCTAssertEqual(HomeViewModel.rangeText(from: oct(30), to: oct(30)), "10월 30일")
    }

    // MARK: - Week strip

    func testWeekDaysRunMondayToSunday() {
        let days = HomeViewModel.weekDays(containing: oct(30), offset: 0, entries: [homeJournal(oct(27))])

        XCTAssertEqual(days.count, 7)
        XCTAssertEqual(days[0].date, oct(26))
        XCTAssertTrue(days[4].isToday)
        XCTAssertTrue(days[5].isFuture && days[6].isFuture)
        XCTAssertFalse(days[3].isFuture)
        XCTAssertTrue(days[1].hasEntry)
        XCTAssertFalse(days[2].hasEntry)
    }

    func testWeekDaysOffsetGoesBackAWeek() {
        let days = HomeViewModel.weekDays(containing: oct(30), offset: -1, entries: [])

        XCTAssertEqual(days[0].date, oct(19))
        XCTAssertFalse(days.contains { $0.isToday || $0.isFuture })
    }

    // MARK: - Principles

    func testPrinciplesRankByEntryCountAndStageByRecency() {
        let entries = [
            homeJournal(oct(20), keywords: [("경청", 0.2)]),
            homeJournal(oct(27), keywords: [("경청", 0.8)]),
            homeJournal(oct(29), keywords: [("휴식", 0.9)]),
        ]

        let principles = HomeViewModel.principles(in: entries)

        XCTAssertEqual(principles.map(\.name), ["경청", "휴식"])
        XCTAssertEqual(principles[0].count, 2)
        XCTAssertEqual(principles[0].stage, 1)
        XCTAssertEqual(principles[1].stage, 0)
    }

    func testRelatedEntriesAreTopThreeByInfluence() {
        let entries = (1...4).map { index in homeJournal(oct(20 + index), keywords: [("경청", Double(index))]) }

        let related = HomeViewModel.principles(in: entries).first?.related ?? []

        XCTAssertEqual(related.map(\.day), [oct(24), oct(23), oct(22)])
    }

    // MARK: - Derived state

    func testTodayEntryMatchesNow() {
        XCTAssertEqual(HomeViewModel(repository: InMemoryJournalRepository(journals: [homeJournal(oct(30)), homeJournal(oct(29))]), now: homeNow).todayEntry?.day, oct(30))
        XCTAssertNil(HomeViewModel(repository: InMemoryJournalRepository(journals: [homeJournal(oct(29))]), now: homeNow).todayEntry)
    }

    func testWeeklySummaryNeedsThreeEntriesThisWeekAndAI() {
        let available = HomeAIStatus.available(.appleIntelligence)
        let three = [homeJournal(oct(12)), homeJournal(oct(20)), homeJournal(oct(29))]

        XCTAssertFalse(HomeViewModel(repository: InMemoryJournalRepository(journals: Array(three.prefix(2))), aiStatus: available, now: homeNow).showsWeeklySummary)
        XCTAssertTrue(HomeViewModel(repository: InMemoryJournalRepository(journals: three), aiStatus: available, now: homeNow).showsWeeklySummary)
        XCTAssertFalse(HomeViewModel(repository: InMemoryJournalRepository(journals: three), aiStatus: .unavailable(.turnedOff), now: homeNow).showsWeeklySummary)
        // Three entries, none this week.
        XCTAssertFalse(HomeViewModel(repository: InMemoryJournalRepository(journals: Array(three.prefix(2)) + [homeJournal(oct(5))]), aiStatus: available, now: homeNow).showsWeeklySummary)
    }

    func testWeeklyRangeLineCountsThisWeek() {
        let model = HomeViewModel(repository: InMemoryJournalRepository(journals: [homeJournal(oct(27)), homeJournal(oct(30)), homeJournal(oct(20))]), now: homeNow)

        XCTAssertEqual(model.weeklyRangeLine, "10월 27일–30일 · 일기 2개")
    }

    func testSensitiveContentInRecentEntries() {
        XCTAssertTrue(HomeViewModel(repository: InMemoryJournalRepository(journals: [homeJournal(oct(27), body: "요즘 죽고 싶다")]), now: homeNow).isSensitive)
        XCTAssertFalse(HomeViewModel(repository: InMemoryJournalRepository(journals: [homeJournal(oct(27), body: "산책을 했다")]), now: homeNow).isSensitive)
    }

    // MARK: - AI cards

    func testFeedbackTogglesOff() {
        let text = AIText(text: "조언", engine: .appleIntelligence, generatedAt: homeNow, sourceJournalIDs: [], feedback: nil)
        let model = HomeViewModel(repository: InMemoryJournalRepository(journals: [homeJournal(oct(29))]), now: homeNow, advice: text)

        model.toggleFeedback(.helpful)
        XCTAssertEqual(model.advicePhase.text?.feedback, .helpful)
        model.toggleFeedback(.helpful)
        XCTAssertNil(model.advicePhase.text?.feedback)
    }

    func testThreeFailuresRest() async {
        struct Failing: HomeAIGenerating {
            func advice(sourceIDs: [UUID], isShort: Bool, engine: AIEngine) async throws -> AIText { throw HomeAIError.generationFailed }
            func writingPrompt(engine: AIEngine) async throws -> String { throw HomeAIError.generationFailed }
            func weeklySummary(sourceIDs: [UUID], engine: AIEngine) async throws -> AIText { throw HomeAIError.generationFailed }
        }
        let model = HomeViewModel(repository: InMemoryJournalRepository(journals: [homeJournal(oct(29))]), now: homeNow, generator: Failing())

        await model.generateAdvice()
        XCTAssertEqual(model.advicePhase, .failed)
        await model.generateAdvice()
        await model.generateAdvice()
        XCTAssertEqual(model.advicePhase, .resting)
    }

    func testNewEntryInRepositoryRewritesAdvice() async throws {
        struct Instant: HomeAIGenerating {
            func advice(sourceIDs: [UUID], isShort: Bool, engine: AIEngine) async throws -> AIText {
                AIText(text: "새 조언", engine: engine, generatedAt: homeNow, sourceJournalIDs: sourceIDs, feedback: nil)
            }
            func writingPrompt(engine: AIEngine) async throws -> String { "질문" }
            func weeklySummary(sourceIDs: [UUID], engine: AIEngine) async throws -> AIText {
                AIText(text: "요약", engine: engine, generatedAt: homeNow, sourceJournalIDs: sourceIDs, feedback: nil)
            }
        }
        let repository = InMemoryJournalRepository(journals: [homeJournal(oct(29))])
        let old = AIText(text: "예전 조언", engine: .appleIntelligence, generatedAt: homeNow, sourceJournalIDs: [], feedback: nil)
        let model = HomeViewModel(repository: repository, now: homeNow, generator: Instant(), advice: old)

        await model.load()
        XCTAssertEqual(model.advicePhase.text?.text, "예전 조언")

        try repository.save(homeJournal(oct(30)))
        XCTAssertEqual(model.entries.count, 2)
        await model.load()
        XCTAssertEqual(model.advicePhase.text?.text, "새 조언")
    }

    func testSensitiveEntriesReplaceAdvice() async {
        let model = HomeViewModel(repository: InMemoryJournalRepository(journals: [homeJournal(oct(29), body: "죽고 싶다")]), now: homeNow)

        await model.generateAdvice()

        XCTAssertEqual(model.advicePhase, .sensitive)
    }
}
