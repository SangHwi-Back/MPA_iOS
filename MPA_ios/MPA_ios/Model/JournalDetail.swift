//
//  [NO AC] Spec: specs/journal/SCREEN_SPEC.md
//
//  JournalDetail.swift
//  MPA_ios
//

import Foundation

/// Everything the keyword sheet shows for one keyword.
struct JournalKeywordSummary {
    let name: String
    /// Principle color stage (0 = most recent … 4 = oldest).
    let stage: Int
    /// Entries where the keyword was extracted and not excluded, newest first.
    let entries: [Journal]
    let firstSeen: Date
    /// True when the keyword is one of the current top principles.
    let isPrinciple: Bool
}

enum JournalCommentError: Error {
    case generationFailed
}

/// Writes the "이 일기에 대한 AI 한마디" text for an entry.
protocol JournalCommentGenerating: Sendable {
    func comment(journalID: UUID, title: String, body: String) async throws -> AIText
}

/// Returns a fixed comment after a short delay. Replace with the on-device model or the API key provider.
struct StubJournalCommentGenerator: JournalCommentGenerating {
    var engine: AIEngine = .appleIntelligence

    func comment(journalID: UUID, title: String, body: String) async throws -> AIText {
        try await Task.sleep(for: .seconds(1.2))
        return AIText(
            text: "듣는 쪽을 택하자 문제의 진짜 모양이 보였네요. 다음 회의에는 첫 질문 하나를 미리 적어 가 보는 건 어때요?",
            engine: engine,
            generatedAt: .now,
            sourceJournalIDs: [journalID],
            feedback: nil
        )
    }
}

/// Local check that swaps the AI comment for the help resource card.
enum JournalSensitiveContent {
    static let phrases = ["죽고 싶", "죽고싶", "자살", "자해", "사라지고 싶", "살기 싫", "살고 싶지 않"]

    static func isSensitive(_ text: String) -> Bool {
        let compact = text.replacingOccurrences(of: " ", with: "")
        return phrases.contains { compact.contains($0.replacingOccurrences(of: " ", with: "")) }
    }
}
