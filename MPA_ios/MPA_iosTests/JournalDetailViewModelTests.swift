//
//  [NO AC] Spec: specs/journal/SCREEN_SPEC.md
//
//  JournalDetailViewModelTests.swift
//  MPA_iosTests
//

import XCTest
@testable import MPA_ios

private final class FakeCommentGenerator: JournalCommentGenerating, @unchecked Sendable {
    var result: Result<AIText, Error>
    var callCount = 0

    init(result: Result<AIText, Error>) {
        self.result = result
    }

    func comment(journalID: UUID, title: String, body: String) async throws -> AIText {
        callCount += 1
        return try result.get()
    }
}

/// Local calendar, matching the formatters and `Journal.init`'s start-of-day.
private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0) -> Date {
    Calendar.current.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
}

private func aiText(_ text: String = "생성된 코멘트", feedback: AIFeedback? = nil) -> AIText {
    AIText(text: text, engine: .appleIntelligence, generatedAt: .now, sourceJournalIDs: [], feedback: feedback)
}

private func keyword(_ name: String, _ influence: Double = 1, excluded: Bool = false) -> JournalKeyword {
    JournalKeyword(name: name, source: .ai, influence: influence, isExcluded: excluded)
}

private func journal(
    day: Date = date(2026, 10, 27),
    title: String = "",
    body: String = "",
    keywords: [JournalKeyword] = [],
    analysisState: AnalysisState = .notAnalyzed,
    aiComment: AIText? = nil
) -> Journal {
    Journal(day: day, createdAt: day, title: title, body: body, keywords: keywords, analysisState: analysisState, aiComment: aiComment)
}

@MainActor
final class JournalDetailViewModelTests: XCTestCase {

    private var generator: FakeCommentGenerator!

    override func setUp() async throws {
        generator = FakeCommentGenerator(result: .success(aiText("새 코멘트")))
    }

    private func makeSUT(_ journal: Journal) -> JournalDetailViewModel {
        JournalDetailViewModel(journal: journal, generator: generator)
    }

    // MARK: - Text

    func testDateTexts() {
        XCTAssertEqual(
            JournalDetailViewModel.dateLine(day: date(2026, 10, 27), createdAt: date(2026, 10, 27, 21, 40)),
            "2026년 10월 27일 화요일 · 오후 9:40"
        )
        XCTAssertEqual(JournalDetailViewModel.shortDate(date(2026, 10, 27)), "10월 27일")
        XCTAssertEqual(JournalDetailViewModel.editedLine(date(2026, 10, 27, 21, 52)), "마지막 수정 10월 27일 오후 9:52")
    }

    func testParagraphsSplitOnBlankLines() {
        XCTAssertEqual(JournalDetailViewModel.paragraphs("a\n\nb\n\n\nc"), ["a", "b", "c"])
    }

    // MARK: - Keyword row

    func testKeywordRowFollowsAnalysisState() {
        XCTAssertEqual(makeSUT(journal(analysisState: .analyzing)).keywordRow, .skeleton)
        XCTAssertEqual(makeSUT(journal(analysisState: .notAnalyzed)).keywordRow, .hidden)

        let unavailable = makeSUT(journal(keywords: [keyword("경청")], analysisState: .unavailable))
        XCTAssertEqual(unavailable.keywordRow, .hidden)
        XCTAssertFalse(unavailable.isAIAvailable)
    }

    func testKeywordRowShowsFiveMostInfluentialVisibleKeywords() {
        let keywords = [
            keyword("다", 0.7), keyword("가", 0.9), keyword("마", 0.5), keyword("나", 0.8),
            keyword("라", 0.6), keyword("바", 0.4), keyword("제외", 1.0, excluded: true),
        ]
        let sut = makeSUT(journal(keywords: keywords, analysisState: .analyzed(at: .now)))

        guard case .chips(let chips) = sut.keywordRow else {
            return XCTFail("Expected chips, got \(sut.keywordRow)")
        }
        XCTAssertEqual(chips.map(\.name), ["가", "나", "다", "라", "마"])
    }

    // MARK: - AI comment

    func testFirstExpandGeneratesOnce() async {
        let sut = makeSUT(journal())

        await sut.toggleComment()
        XCTAssertEqual(sut.commentPhase, .loaded(aiTextMatching(sut)))
        XCTAssertEqual(sut.journal.aiComment?.text, "새 코멘트")
        XCTAssertTrue(sut.revealsCommentByWord)

        await sut.toggleComment()
        await sut.toggleComment()
        XCTAssertTrue(sut.isCommentExpanded)
        XCTAssertEqual(generator.callCount, 1)
    }

    func testCachedCommentIsNotRegenerated() async {
        let sut = makeSUT(journal(aiComment: aiText("캐시")))
        guard case .loaded(let cached) = sut.commentPhase else {
            return XCTFail("Expected loaded, got \(sut.commentPhase)")
        }
        XCTAssertEqual(cached.text, "캐시")

        await sut.toggleComment()
        XCTAssertEqual(generator.callCount, 0)
        XCTAssertFalse(sut.revealsCommentByWord)
    }

    func testFailureThenRetry() async {
        generator.result = .failure(JournalCommentError.generationFailed)
        let sut = makeSUT(journal())

        await sut.toggleComment()
        XCTAssertEqual(sut.commentPhase, .failed)

        generator.result = .success(aiText("다시"))
        await sut.generateComment()
        XCTAssertEqual(sut.journal.aiComment?.text, "다시")
    }

    func testFeedbackTogglesOff() {
        let sut = makeSUT(journal(aiComment: aiText()))

        sut.toggleFeedback(.helpful)
        XCTAssertEqual(sut.journal.aiComment?.feedback, .helpful)

        sut.toggleFeedback(.notHelpful)
        XCTAssertEqual(sut.journal.aiComment?.feedback, .notHelpful)

        sut.toggleFeedback(.notHelpful)
        XCTAssertNil(sut.journal.aiComment?.feedback)
    }

    func testRegenerateCallsGeneratorAgain() async {
        let sut = makeSUT(journal())
        await sut.generateComment()
        await sut.regenerateComment()

        XCTAssertEqual(generator.callCount, 2)
    }

    // MARK: - Keyword sheet

    func testKeywordSummaryListsMatchingEntriesNewestFirst() {
        let entries = [
            journal(day: date(2026, 10, 20), keywords: [keyword("경청")]),
            journal(day: date(2026, 9, 14), keywords: [keyword("경청")]),
            journal(day: date(2026, 10, 27), keywords: [keyword("경청")]),
            journal(day: date(2026, 10, 26), keywords: [keyword("경청", excluded: true)]),
        ]

        let summary = JournalDetailViewModel.keywordSummary(named: "경청", in: entries, stages: ["경청": 1])

        XCTAssertEqual(summary?.entries.map(\.day), [date(2026, 10, 27), date(2026, 10, 20), date(2026, 9, 14)])
        XCTAssertEqual(summary?.firstSeen, date(2026, 9, 14))
        XCTAssertEqual(summary?.stage, 1)
        XCTAssertEqual(summary?.isPrinciple, true)
        XCTAssertNil(JournalDetailViewModel.keywordSummary(named: "없음", in: entries, stages: [:]))
    }

    func testTopPrinciplesDropsTheRarestKeyword() {
        let common = ["가", "나", "다", "라", "마"].flatMap { name in
            [journal(day: date(2026, 10, 20), keywords: [keyword(name)]),
             journal(day: date(2026, 10, 21), keywords: [keyword(name)])]
        }
        let entries = common + [journal(day: date(2026, 10, 27), keywords: [keyword("희귀")])]

        let principles = JournalDetailViewModel.topPrinciples(in: entries)

        XCTAssertEqual(principles.count, JournalDetailViewModel.principleCount)
        XCTAssertFalse(principles.contains("희귀"))
    }

    // MARK: - Other

    func testSensitiveContentDetection() {
        XCTAssertTrue(makeSUT(journal(body: "요즘 죽고 싶다는 생각이 들었다")).isSensitive)
        XCTAssertTrue(JournalSensitiveContent.isSensitive("자 살"))
        XCTAssertFalse(makeSUT(journal(body: "회의에서 끝까지 들었다")).isSensitive)
    }

    func testChangeDayStoresStartOfDay() {
        let sut = makeSUT(journal())
        sut.changeDay(to: date(2026, 10, 28, 15, 30))
        XCTAssertEqual(sut.journal.day, date(2026, 10, 28))
    }

    private func aiTextMatching(_ sut: JournalDetailViewModel) -> AIText {
        sut.journal.aiComment ?? aiText()
    }
}
