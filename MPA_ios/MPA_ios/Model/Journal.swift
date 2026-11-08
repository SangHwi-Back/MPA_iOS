//
//  Journal.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/2/26.
//

import Foundation
import SwiftData

@Model
final class Journal {
    private(set) var id: UUID
    /// The day this entry belongs to (start of day, local calendar).
    /// Users can change it from the editor's date button. Several entries per day are allowed.
    var day: Date
    /// When the entry was first saved (shown as "오후 9:40" in detail).
    private(set) var createdAt: Date
    /// Set only after the entry is edited post-creation ("마지막 수정 …" is shown only when non-nil).
    var editedAt: Date?
    /// Optional. Empty means "use the first line of the body" (see `displayTitle`).
    var title: String
    var body: String
    /// The "글감" question the entry was started from. Stored, not shown in detail.
    var prompt: String?
    /// Ordered as shown in the editor grid (drag to reorder). Max `Journal.maxPhotos`.
    var photos: [JournalPhoto]
    /// AI-extracted plus user-added keywords, including ones the user excluded.
    var keywords: [JournalKeyword]
    var analysisState: AnalysisState
    /// Cached "이 일기에 대한 AI 한마디". Generated on first expand, cleared when the entry is edited.
    var aiComment: AIText?
    
    init(
        id: UUID = UUID(),
        day: Date = Calendar.current.startOfDay(for: .now),
        createdAt: Date = .now,
        editedAt: Date? = nil,
        title: String = "",
        body: String = "",
        prompt: String? = nil,
        photos: [JournalPhoto] = [],
        keywords: [JournalKeyword] = [],
        analysisState: AnalysisState = .notAnalyzed,
        aiComment: AIText? = nil
    ) {
        self.id = id
        self.day = Calendar.current.startOfDay(for: day)
        self.createdAt = createdAt
        self.editedAt = editedAt
        self.title = title
        self.body = body
        self.prompt = prompt
        self.photos = photos
        self.keywords = keywords
        self.analysisState = analysisState
        self.aiComment = aiComment
    }
}

// MARK: - Limits

extension Journal {
    static let maxPhotos = 10
    /// Keyword chips shown on a list item.
    static let maxKeywordsInList = 2
    /// Keyword chips shown in detail.
    static let maxKeywordsInDetail = 5
    /// Recommended keyword length (characters).
    static let keywordLength = 2...4
}

// MARK: - Derived values

extension Journal {
    /// Title, or the first non-empty line of the body when the title is empty.
    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        return body
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty } ?? ""
    }
    
    /// Body text for the 2-line list preview (line breaks collapsed).
    /// When the title came from the body, the first line is skipped.
    var previewText: String {
        var lines = body
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !lines.isEmpty {
            lines.removeFirst()
        }
        return lines.joined(separator: " ")
    }
    
    /// An entry with no title, body, or photos is discarded when the editor closes.
    var isEmpty: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && photos.isEmpty
    }
    
    var isEdited: Bool { editedAt != nil }
    
    /// First photo, used as the list thumbnail ("+N" badge = `photos.count - 1`).
    var thumbnail: JournalPhoto? { photos.first }
    
    /// Keywords to display: not excluded, most influential first.
    var visibleKeywords: [JournalKeyword] {
        keywords
            .filter { !$0.isExcluded }
            .sorted { $0.influence > $1.influence }
    }
}

// MARK: - Mutations

extension Journal {
    /// Apply an edit to the text. Invalidates AI output so it is regenerated.
    func edit(title: String? = nil, body: String? = nil, at date: Date = .now) {
        if let title { self.title = title }
        if let body { self.body = body }
        editedAt = date
        aiComment = nil
        analysisState = .notAnalyzed
    }
    
    /// Replace AI keywords after (re)analysis while keeping the user's choices:
    /// user-added keywords stay, and keywords the user excluded stay excluded.
    func applyAnalysis(_ extracted: [JournalKeyword], at date: Date = .now) {
        let excludedNames = Set(keywords.filter(\.isExcluded).map(\.name))
        let userAdded = keywords.filter { $0.source == .user }
        let userNames = Set(userAdded.map(\.name))
        
        let ai = extracted
            .filter { !userNames.contains($0.name) }
            .map { keyword -> JournalKeyword in
                var k = keyword
                k.isExcluded = excludedNames.contains(k.name)
                return k
            }
        keywords = userAdded + ai
        analysisState = .analyzed(at: date)
    }
    
    /// "✕" on a keyword chip in the editor.
    func excludeKeyword(named name: String) {
        guard let i = keywords.firstIndex(where: { $0.name == name }) else { return }
        if keywords[i].source == .user {
            keywords.remove(at: i)
        } else {
            keywords[i].isExcluded = true
        }
    }
    
    /// "+ 추가" in the editor.
    func addKeyword(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let i = keywords.firstIndex(where: { $0.name == trimmed }) {
            keywords[i].isExcluded = false
        } else {
            keywords.append(JournalKeyword(name: trimmed, source: .user, influence: 1))
        }
    }
}

// MARK: - Photo

struct JournalPhoto: Identifiable, Codable, Hashable {
    let id: UUID
    /// File name inside the app's private photo directory (never a Photos library reference).
    var fileName: String
    /// Edited from photo detail. Not shown on thumbnails. Never sent to an external API.
    var caption: String
    
    init(id: UUID = UUID(), fileName: String, caption: String = "") {
        self.id = id
        self.fileName = fileName
        self.caption = caption
    }
}

// MARK: - Keyword

struct JournalKeyword: Codable, Hashable {
    /// 2–4 characters recommended (e.g. "경청").
    var name: String
    var source: KeywordSource
    /// 0…1. How strongly this entry expresses the keyword. Used to order chips and
    /// to pick the "top 3 entries" in the principle bubble menu.
    var influence: Double
    /// AI keyword the user removed with "✕". Kept so re-analysis does not bring it back.
    var isExcluded: Bool = false
}

enum KeywordSource: String, Codable, Hashable {
    case ai
    case user
}

// MARK: - Analysis state

enum AnalysisState: Codable, Hashable {
    /// Not analyzed yet (new or edited). Keyword section hidden.
    case notAnalyzed
    /// "키워드를 찾는 중…" with skeleton chips.
    case analyzing
    case analyzed(at: Date)
    case failed
    /// No on-device AI and no API key ("일기 앱 모드"). Keyword section hidden.
    case unavailable
}

// MARK: - AI generated text

/// Any AI-generated text (AI 한마디, 오늘의 조언, 주간 요약, 원칙 정의).
struct AIText: Codable, Hashable {
    var text: String
    var engine: AIEngine
    var generatedAt: Date
    /// Entries the text was based on (shown as source chips where the design has them).
    var sourceJournalIDs: [UUID]
    var feedback: AIFeedback?
}

enum AIFeedback: String, Codable, Hashable {
    case helpful
    case notHelpful
}

enum AIEngine: String, Codable, Hashable {
    case appleIntelligence
    case geminiNano
    case geminiAPIKey
    case openAIAPIKey
    
    /// Source label shown under AI content.
    var sourceLabel: String {
        switch self {
        case .appleIntelligence: return "✦ Apple Intelligence로 기기에서 생성됨"
        case .geminiNano:        return "✦ 기기 내 AI로 생성됨"
        case .geminiAPIKey:      return "✦ Gemini (내 API 키)"
        case .openAIAPIKey:      return "✦ OpenAI (내 API 키)"
        }
    }
    
    var isOnDevice: Bool {
        self == .appleIntelligence || self == .geminiNano
    }
}

// MARK: - Sample (design example data)

extension Journal {
    static let sample: Journal = {
        let calendar = Calendar(identifier: .gregorian)
        let day = calendar.date(from: DateComponents(year: 2026, month: 10, day: 27))!
        let created = calendar.date(from: DateComponents(year: 2026, month: 10, day: 27, hour: 21, minute: 40))!
        return Journal(
            day: day,
            createdAt: created,
            editedAt: created.addingTimeInterval(12 * 60),
            title: "회의에서 말을 끊지 않기",
            body: """
            오늘 주간 회의에서 끝까지 들어 보기로 마음먹었다. 민지 씨가 일정 이야기를 꺼냈을 때, 평소 같았으면 중간에 끼어들어 해결책부터 말했을 거다.
            
            이번에는 말이 끝날 때까지 기다렸다. 그랬더니 문제는 일정이 아니라 리뷰가 한 사람에게 몰려 있다는 데 있었다.
            
            내가 하려던 질문이 달라졌다. 다음 회의에도 먼저 묻고, 그다음에 말해야겠다.
            """,
            prompt: "오늘 누군가의 말을 끝까지 들었던 순간이 있었나요?",
            photos: [
                JournalPhoto(fileName: "whiteboard.jpg", caption: "회의실 화이트보드"),
                JournalPhoto(fileName: "coffee.jpg", caption: "회의 끝나고 마신 커피"),
            ],
            keywords: [
                JournalKeyword(name: "경청", source: .ai, influence: 0.92),
                JournalKeyword(name: "솔직함", source: .ai, influence: 0.61),
            ],
            analysisState: .analyzed(at: created.addingTimeInterval(60))
        )
    }()
}
