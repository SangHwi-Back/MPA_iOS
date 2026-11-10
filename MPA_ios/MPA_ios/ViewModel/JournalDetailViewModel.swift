//
//  [NO AC] Spec: specs/journal/SCREEN_SPEC.md
//
//  JournalDetailViewModel.swift
//  MPA_ios
//

import Foundation
import Observation

@MainActor
@Observable
final class JournalDetailViewModel {

    enum CommentPhase: Equatable {
        case idle
        case loading
        case loaded(AIText)
        case failed
    }

    enum KeywordRow: Equatable {
        case hidden
        case skeleton
        case chips([JournalKeyword])
    }

    /// Number of keywords that count as the current principles.
    static let principleCount = 5

    let journal: Journal
    /// Not remembered per entry: every visit starts collapsed.
    var isCommentExpanded: Bool
    private(set) var commentPhase: CommentPhase
    /// True only right after a fresh generation, so the text fades in word by word once.
    private(set) var revealsCommentByWord = false
    /// The keyword whose sheet is open.
    var presentedKeyword: String?

    private let generator: any JournalCommentGenerating

    init(
        journal: Journal,
        generator: any JournalCommentGenerating = StubJournalCommentGenerator(),
        isCommentExpanded: Bool = false,
        presentedKeyword: String? = nil
    ) {
        self.journal = journal
        self.generator = generator
        self.isCommentExpanded = isCommentExpanded
        self.presentedKeyword = presentedKeyword
        self.commentPhase = journal.aiComment.map(CommentPhase.loaded) ?? .idle
    }

    // MARK: - Derived

    /// No on-device AI and no API key: the keyword row and the AI comment are hidden.
    var isAIAvailable: Bool { journal.analysisState != .unavailable }

    var isSensitive: Bool {
        JournalSensitiveContent.isSensitive(journal.title + "\n" + journal.body)
    }

    var hasTitle: Bool {
        !journal.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var keywordRow: KeywordRow {
        switch journal.analysisState {
        case .analyzing:
            return .skeleton
        case .analyzed:
            let keywords = Array(journal.visibleKeywords.prefix(Journal.maxKeywordsInDetail))
            return keywords.isEmpty ? .hidden : .chips(keywords)
        case .notAnalyzed, .failed, .unavailable:
            return .hidden
        }
    }

    var paragraphs: [String] { Self.paragraphs(journal.body) }

    // MARK: - AI comment

    func toggleComment() async {
        isCommentExpanded.toggle()
        guard isCommentExpanded, commentPhase == .idle else { return }
        await generateComment()
    }

    func generateComment() async {
        commentPhase = .loading
        do {
            let comment = try await generator.comment(journalID: journal.id, title: journal.title, body: journal.body)
            journal.aiComment = comment
            revealsCommentByWord = true
            commentPhase = .loaded(comment)
        } catch {
            commentPhase = .failed
        }
    }

    func regenerateComment() async {
        journal.aiComment = nil
        await generateComment()
    }

    /// Tapping the selected thumb again clears it.
    func toggleFeedback(_ feedback: AIFeedback) {
        guard case .loaded(var comment) = commentPhase else { return }
        comment.feedback = comment.feedback == feedback ? nil : feedback
        journal.aiComment = comment
        revealsCommentByWord = false
        commentPhase = .loaded(comment)
    }

    // MARK: - Mutations

    func changeDay(to date: Date) {
        journal.day = Calendar.current.startOfDay(for: date)
    }

    // MARK: - Keyword sheet

    /// Summary for the keyword sheet, built from every entry in the app.
    static func keywordSummary(named name: String, in entries: [Journal], stages: [String: Int]) -> JournalKeywordSummary? {
        let matching = entries
            .filter { entry in entry.visibleKeywords.contains { $0.name == name } }
            .sorted { $0.day == $1.day ? $0.createdAt > $1.createdAt : $0.day > $1.day }
        guard let firstSeen = matching.map(\.day).min() else { return nil }
        return JournalKeywordSummary(
            name: name,
            stage: stages[name] ?? 0,
            entries: matching,
            firstSeen: firstSeen,
            isPrinciple: topPrinciples(in: entries).contains(name)
        )
    }

    /// The keywords found in the most entries, ties broken by the most recent appearance.
    static func topPrinciples(in entries: [Journal]) -> [String] {
        var counts: [String: Int] = [:]
        var lastSeen: [String: Date] = [:]
        for entry in entries {
            for keyword in Set(entry.visibleKeywords.map(\.name)) {
                counts[keyword, default: 0] += 1
                lastSeen[keyword] = max(lastSeen[keyword] ?? entry.day, entry.day)
            }
        }
        return counts.keys
            .sorted { lhs, rhs in
                if counts[lhs] != counts[rhs] { return counts[lhs]! > counts[rhs]! }
                if lastSeen[lhs] != lastSeen[rhs] { return lastSeen[lhs]! > lastSeen[rhs]! }
                return lhs < rhs
            }
            .prefix(principleCount)
            .map { $0 }
    }

    // MARK: - Text

    /// Paragraphs separated by blank lines.
    static func paragraphs(_ body: String) -> [String] {
        body
            .components(separatedBy: "\n")
            .split { $0.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { $0.joined(separator: "\n") }
    }

    private static func formatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = format
        return formatter
    }

    /// "2026년 10월 27일 화요일 · 오후 9:40"
    static func dateLine(day: Date, createdAt: Date) -> String {
        "\(formatter("yyyy년 M월 d일 EEEE").string(from: day)) · \(formatter("a h:mm").string(from: createdAt))"
    }

    /// "10월 27일"
    static func shortDate(_ date: Date) -> String {
        formatter("M월 d일").string(from: date)
    }

    /// "마지막 수정 10월 27일 오후 9:52"
    static func editedLine(_ date: Date) -> String {
        "마지막 수정 \(formatter("M월 d일 a h:mm").string(from: date))"
    }
}
