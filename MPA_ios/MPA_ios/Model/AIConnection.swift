//
//  [NO AC] Spec: specs/settings/SCREEN_SPEC.md
//
//  AIConnection.swift
//  MPA_ios
//

import Foundation

enum AIProvider: String, CaseIterable, Identifiable {
    case gemini
    case openAI

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gemini: return "Gemini"
        case .openAI: return "OpenAI"
        }
    }

    /// The company whose servers receive the data, as named in the consent sheet.
    var companyName: String {
        switch self {
        case .gemini: return "Google"
        case .openAI: return "OpenAI"
        }
    }

    var keyPrefix: String {
        switch self {
        case .gemini: return "AIza"
        case .openAI: return "sk-"
        }
    }

    var keyIssueURL: URL {
        switch self {
        case .gemini: return URL(string: "https://aistudio.google.com/apikey")!
        case .openAI: return URL(string: "https://platform.openai.com/api-keys")!
        }
    }
}

enum AIUnavailableReason: Equatable {
    case unsupported
    case turnedOff
    case downloading

    var message: String {
        switch self {
        case .unsupported:
            return "이 기기는 Apple Intelligence를 지원하지 않아요. 내 API 키를 연결하면 조언·요약·원칙을 쓸 수 있어요."
        case .turnedOff:
            return "Apple Intelligence가 꺼져 있어요. 내 API 키를 연결하면 조언·요약·원칙을 쓸 수 있어요."
        case .downloading:
            return "Apple Intelligence를 내려받는 중이에요. 내 API 키를 연결하면 바로 조언·요약·원칙을 쓸 수 있어요."
        }
    }
}

struct AIKeyConnection: Equatable {
    var provider: AIProvider
    var maskedKey: String
    var lastTestedAt: Date
    var consentGrantedAt: Date
}

enum AIConnectionState: Equatable {
    case notConnected(AIUnavailableReason)
    case deviceAI(hasStandbyKey: Bool)
    case connected(AIKeyConnection)
    case keyError(AIKeyConnection)

    /// The key connection shown in the connection info section, if any.
    var keyConnection: AIKeyConnection? {
        switch self {
        case .connected(let connection), .keyError(let connection): return connection
        case .notConnected, .deviceAI: return nil
        }
    }
}

struct AIConsentRecord: Equatable {
    var provider: AIProvider
    var grantedAt: Date
}

enum AIKeyTestFailure: Error, Equatable {
    case invalidKey
    case quotaExceeded
    case offline

    var message: String {
        switch self {
        case .invalidKey: return "키가 올바르지 않아요"
        case .quotaExceeded: return "한도를 초과했어요"
        case .offline: return "인터넷 연결을 확인해 주세요"
        }
    }
}

protocol AIKeyTesting: Sendable {
    /// Returns nil when the key works.
    func test(key: String, provider: AIProvider) async -> AIKeyTestFailure?
}

/// Always succeeds after a short delay. Replace with a real provider request.
struct StubAIKeyTester: AIKeyTesting {
    func test(key: String, provider: AIProvider) async -> AIKeyTestFailure? {
        try? await Task.sleep(for: .seconds(1))
        return nil
    }
}
