//
//  [NO AC] Spec: specs/home/SCREEN_SPEC.md
//
//  Home.swift
//  MPA_ios
//

import Foundation

/// What the AI cards on 오늘 can do right now (Part A 2, Part B 2).
enum HomeAIStatus: Equatable {
    case available(AIEngine)
    /// API key mode whose key was rejected. Cards show "내 API 키를 확인해 주세요".
    case keyError(AIEngine)
    /// No on-device AI and no API key, or the model is still downloading ("일기 앱 모드").
    case unavailable(AIUnavailableReason)

    init(connection: AIConnectionState, deviceEngine: AIEngine = .appleIntelligence) {
        switch connection {
        case .notConnected(let reason): self = .unavailable(reason)
        case .deviceAI: self = .available(deviceEngine)
        case .connected(let key): self = .available(key.provider.engine)
        case .keyError(let key): self = .keyError(key.provider.engine)
        }
    }

    var isAvailable: Bool {
        if case .unavailable = self { return false }
        return true
    }

    var engine: AIEngine? {
        switch self {
        case .available(let engine), .keyError(let engine): return engine
        case .unavailable: return nil
        }
    }

    var unavailableReason: AIUnavailableReason? {
        if case .unavailable(let reason) = self { return reason }
        return nil
    }
}

extension AIProvider {
    var engine: AIEngine {
        switch self {
        case .gemini: return .geminiAPIKey
        case .openAI: return .openAIAPIKey
        }
    }
}

extension AIUnavailableReason {
    /// Alert title (3.12). Only the download case gets its own title.
    var homeAlertTitle: String {
        self == .downloading ? "AI를 준비하고 있어요" : "AI 기능을 사용할 수 없어요"
    }

    /// Alert body (3.12): cause sentence + the shared sentence.
    var homeAlertMessage: String {
        let cause: String
        switch self {
        case .unsupported: cause = "이 기기는 Apple Intelligence를 지원하지 않아요."
        case .turnedOff: cause = "설정에서 Apple Intelligence가 꺼져 있어요."
        case .downloading: cause = "AI 모델을 내려받고 있어요. 준비되면 자동으로 켜져요."
        }
        return cause + "\n일기 쓰기는 그대로 사용할 수 있어요."
    }
}

/// Which section set the screen shows (Part A 2, state matrix).
enum HomeLayout: Equatable {
    /// No entries yet: "반가워요" + illustration + example questions.
    case firstRun
    /// AI available, 1–2 entries: principle progress instead of bubbles.
    case early
    /// AI available, 3 or more entries.
    case full
    /// No AI: today card + week strip + recent entries.
    case diary
}

/// One bubble in "나의 원칙".
struct HomePrinciple: Identifiable, Equatable {
    let name: String
    /// Number of entries the keyword appears in.
    let count: Int
    /// Recency color stage (0 = most recent … 4 = oldest).
    let stage: Int
    /// Up to 3 related entries, most influential first.
    let related: [Journal]

    var id: String { name }

    static func == (lhs: HomePrinciple, rhs: HomePrinciple) -> Bool {
        lhs.name == rhs.name && lhs.count == rhs.count && lhs.stage == rhs.stage
            && lhs.related.map(\.id) == rhs.related.map(\.id)
    }
}

/// One cell of the 이번 주 strip.
struct HomeWeekDay: Identifiable, Equatable {
    let date: Date
    let hasEntry: Bool
    let isToday: Bool
    let isFuture: Bool

    var id: Date { date }
}

/// State of one AI card (Part B 2). Failures are not stored; only `AIText` is cached.
enum HomeAIPhase: Equatable {
    case idle
    case loading
    case loaded(AIText)
    case failed
    /// Three failures in a row today: "오늘은 쉬어 갈게요".
    case resting
    case keyError
    /// Recent entries look distressing: the help resource card replaces the advice.
    case sensitive

    var text: AIText? {
        if case .loaded(let text) = self { return text }
        return nil
    }
}

enum HomeAIError: Error {
    case generationFailed
}

/// Writes the AI texts on 오늘.
protocol HomeAIGenerating: Sendable {
    func advice(sourceIDs: [UUID], isShort: Bool, engine: AIEngine) async throws -> AIText
    func writingPrompt(engine: AIEngine) async throws -> String
    func weeklySummary(sourceIDs: [UUID], engine: AIEngine) async throws -> AIText
}

/// Returns the design copy after a short delay. Replace with the on-device model or the API key provider.
struct StubHomeAIGenerator: HomeAIGenerating {
    var delay: Duration = .seconds(1.2)

    private static let prompts = [
        "오늘 누군가의 말을 끝까지 들었던 순간이 있었나요?",
        "오늘 가장 오래 머문 생각은 무엇이었나요?",
        "최근 누군가에게 고마웠던 순간이 있나요?",
    ]

    func advice(sourceIDs: [UUID], isShort: Bool, engine: AIEngine) async throws -> AIText {
        try await Task.sleep(for: delay)
        return AIText(
            text: isShort ? HomeSamples.shortAdvice : HomeSamples.advice,
            engine: engine,
            generatedAt: .now,
            sourceJournalIDs: sourceIDs,
            feedback: nil
        )
    }

    func writingPrompt(engine: AIEngine) async throws -> String {
        try await Task.sleep(for: delay / 2)
        return Self.prompts.randomElement()!
    }

    func weeklySummary(sourceIDs: [UUID], engine: AIEngine) async throws -> AIText {
        try await Task.sleep(for: delay)
        return AIText(
            text: HomeSamples.weeklySummary,
            engine: engine,
            generatedAt: .now,
            sourceJournalIDs: sourceIDs,
            feedback: nil
        )
    }
}

/// Fixed copy from the design (also used by the previews).
enum HomeSamples {
    static let advice = "요즘 일기에 ‘끝까지 듣기’가 자주 보여요. 오늘은 대화 하나를 골라, 상대의 말이 끝난 뒤 질문을 하나만 더 건네 보는 건 어때요?"
    static let shortAdvice = "두 일기 모두 걷기로 하루를 정리했네요. 내일도 십 분만 걸어 보는 건 어때요?"
    static let writingPrompt = "오늘 누군가의 말을 끝까지 들었던 순간이 있었나요?"
    static let weeklySummary = "네 편의 일기 중 세 편이 ‘듣기’와 ‘걷기’로 하루를 정리했어요. 주 초반보다 문장이 차분해졌어요."
    static let weeklyMood = "차분함이 늘었어요"
    /// 3.14, fixed, no ✦.
    static let exampleQuestions = [
        "오늘 가장 오래 머문 생각은 무엇이었나요?",
        "최근 누군가에게 고마웠던 순간이 있나요?",
        "내일의 나에게 한마디 한다면?",
    ]
}
