package com.example.mpa_android.model

import kotlinx.coroutines.delay

enum class AIProvider(
    val displayName: String,
    val companyName: String,
    val keyPrefix: String,
    val keyIssueUrl: String,
) {
    GEMINI("Gemini", "Google", "AIza", "https://aistudio.google.com/apikey"),
    OPENAI("OpenAI", "OpenAI", "sk-", "https://platform.openai.com/api-keys"),
}

enum class AIUnavailableReason(val message: String) {
    UNSUPPORTED("이 기기는 Gemini Nano를 지원하지 않아요. 내 API 키를 연결하면 조언·요약·원칙을 쓸 수 있어요."),
    TURNED_OFF("Gemini Nano가 꺼져 있어요. 내 API 키를 연결하면 조언·요약·원칙을 쓸 수 있어요."),
    DOWNLOADING("Gemini Nano를 내려받는 중이에요. 내 API 키를 연결하면 바로 조언·요약·원칙을 쓸 수 있어요."),
}

data class AIKeyConnection(
    val provider: AIProvider,
    val maskedKey: String,
    val lastTestedAtMillis: Long,
    val consentGrantedAtMillis: Long,
)

sealed interface AIConnectionState {
    data class NotConnected(val reason: AIUnavailableReason) : AIConnectionState
    data class DeviceAI(val hasStandbyKey: Boolean) : AIConnectionState
    data class Connected(val connection: AIKeyConnection) : AIConnectionState
    data class KeyError(val connection: AIKeyConnection) : AIConnectionState
}

/** The key connection shown in the connection info section, if any. */
val AIConnectionState.keyConnection: AIKeyConnection?
    get() = when (this) {
        is AIConnectionState.Connected -> connection
        is AIConnectionState.KeyError -> connection
        is AIConnectionState.NotConnected, is AIConnectionState.DeviceAI -> null
    }

data class AIConsentRecord(
    val provider: AIProvider,
    val grantedAtMillis: Long,
)

enum class AIKeyTestFailure(val message: String) {
    INVALID_KEY("키가 올바르지 않아요"),
    QUOTA_EXCEEDED("한도를 초과했어요"),
    OFFLINE("인터넷 연결을 확인해 주세요"),
}

fun interface AIKeyTester {
    /** Returns null when the key works. */
    suspend fun test(key: String, provider: AIProvider): AIKeyTestFailure?
}

/** Always succeeds after a short delay. Replace with a real provider request. */
class StubAIKeyTester : AIKeyTester {
    override suspend fun test(key: String, provider: AIProvider): AIKeyTestFailure? {
        delay(1_000)
        return null
    }
}

fun interface AIDeviceStateProvider {
    fun current(): AIConnectionState
}
