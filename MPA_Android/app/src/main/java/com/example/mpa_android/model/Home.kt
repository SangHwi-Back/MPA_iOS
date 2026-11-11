// [NO AC] Spec: specs/home/SCREEN_SPEC.md
@file:OptIn(ExperimentalTime::class)

package com.example.mpa_android.model

import com.android.identity.util.UUID
import java.time.LocalDate
import kotlin.time.Clock
import kotlin.time.ExperimentalTime
import kotlinx.coroutines.delay

/** What the AI cards on 오늘 can do right now (Part A 2, Part B 2). */
sealed interface HomeAIStatus {
    data class Available(override val engine: AIEngine) : HomeAIStatus
    /** API key mode whose key was rejected. Cards show "내 API 키를 확인해 주세요". */
    data class KeyError(override val engine: AIEngine) : HomeAIStatus
    /** No on-device AI and no API key, or the model is still downloading ("일기 앱 모드"). */
    data class Unavailable(val reason: AIUnavailableReason) : HomeAIStatus

    val isAvailable: Boolean get() = this !is Unavailable

    val engine: AIEngine? get() = null

    companion object {
        fun from(connection: AIConnectionState, deviceEngine: AIEngine = AIEngine.GEMINI_NANO): HomeAIStatus =
            when (connection) {
                is AIConnectionState.NotConnected -> Unavailable(connection.reason)
                is AIConnectionState.DeviceAI -> Available(deviceEngine)
                is AIConnectionState.Connected -> Available(connection.connection.provider.engine)
                is AIConnectionState.KeyError -> KeyError(connection.connection.provider.engine)
            }
    }
}

val AIProvider.engine: AIEngine
    get() = when (this) {
        AIProvider.GEMINI -> AIEngine.GEMINI_API_KEY
        AIProvider.OPENAI -> AIEngine.OPENAI_API_KEY
    }

/** Dialog title (3.12). Only the download case gets its own title. */
val AIUnavailableReason.homeAlertTitle: String
    get() = if (this == AIUnavailableReason.DOWNLOADING) "AI를 준비하고 있어요" else "AI 기능을 사용할 수 없어요"

/** Dialog body (3.12): cause sentence + the shared sentence. */
val AIUnavailableReason.homeAlertMessage: String
    get() {
        val cause = when (this) {
            AIUnavailableReason.UNSUPPORTED -> "이 기기는 Gemini Nano를 지원하지 않아요."
            AIUnavailableReason.TURNED_OFF -> "기기 내 AI(Gemini Nano)가 꺼져 있어요."
            AIUnavailableReason.DOWNLOADING -> "AI 모델을 내려받고 있어요. 준비되면 자동으로 켜져요."
        }
        return "$cause\n일기 쓰기는 그대로 사용할 수 있어요."
    }

/** Which section set the screen shows (Part A 2, state matrix). */
enum class HomeLayout {
    /** No entries yet: "반가워요" + illustration + example questions. */
    FIRST_RUN,
    /** AI available, 1–2 entries: principle progress instead of bubbles. */
    EARLY,
    /** AI available, 3 or more entries. */
    FULL,
    /** No AI: today card + week strip + recent entries. */
    DIARY,
}

/** One bubble in "나의 원칙". */
data class HomePrinciple(
    val name: String,
    /** Number of entries the keyword appears in. */
    val count: Int,
    /** Recency color stage (0 = most recent … 4 = oldest). */
    val stage: Int,
    /** Up to 3 related entries, most influential first. */
    val related: List<Journal>,
)

/** One cell of the 이번 주 strip. */
data class HomeWeekDay(
    val date: LocalDate,
    val hasEntry: Boolean,
    val isToday: Boolean,
    val isFuture: Boolean,
)

/** State of one AI card (Part B 2). Failures are not stored; only [AIText] is cached. */
sealed interface HomeAIPhase {
    data object Idle : HomeAIPhase
    data object Loading : HomeAIPhase
    data class Loaded(override val text: AIText) : HomeAIPhase
    data object Failed : HomeAIPhase
    /** Three failures in a row today: "오늘은 쉬어 갈게요". */
    data object Resting : HomeAIPhase
    data object KeyError : HomeAIPhase
    /** Recent entries look distressing: the help resource card replaces the advice. */
    data object Sensitive : HomeAIPhase

    val text: AIText? get() = null
}

/** Writes the AI texts on 오늘. */
interface HomeAIGenerator {
    suspend fun advice(sourceIds: List<UUID>, isShort: Boolean, engine: AIEngine): AIText
    suspend fun writingPrompt(engine: AIEngine): String
    suspend fun weeklySummary(sourceIds: List<UUID>, engine: AIEngine): AIText
}

/** Returns the design copy after a short delay. Replace with Gemini Nano or the API key provider. */
class StubHomeAIGenerator(private val delayMillis: Long = 1_200) : HomeAIGenerator {
    private val prompts = listOf(
        HomeSamples.WRITING_PROMPT,
        "오늘 가장 오래 머문 생각은 무엇이었나요?",
        "최근 누군가에게 고마웠던 순간이 있나요?",
    )

    override suspend fun advice(sourceIds: List<UUID>, isShort: Boolean, engine: AIEngine): AIText {
        delay(delayMillis)
        return AIText(
            text = if (isShort) HomeSamples.SHORT_ADVICE else HomeSamples.ADVICE,
            engine = engine,
            generatedAt = Clock.System.now(),
            sourceJournalIds = sourceIds,
        )
    }

    override suspend fun writingPrompt(engine: AIEngine): String {
        delay(delayMillis / 2)
        return prompts.random()
    }

    override suspend fun weeklySummary(sourceIds: List<UUID>, engine: AIEngine): AIText {
        delay(delayMillis)
        return AIText(
            text = HomeSamples.WEEKLY_SUMMARY,
            engine = engine,
            generatedAt = Clock.System.now(),
            sourceJournalIds = sourceIds,
        )
    }
}

/** Fixed copy from the design (also used by the previews). */
object HomeSamples {
    const val ADVICE = "요즘 일기에 ‘끝까지 듣기’가 자주 보여요. 오늘은 대화 하나를 골라, 상대의 말이 끝난 뒤 질문을 하나만 더 건네 보는 건 어때요?"
    const val SHORT_ADVICE = "두 일기 모두 걷기로 하루를 정리했네요. 내일도 십 분만 걸어 보는 건 어때요?"
    const val WRITING_PROMPT = "오늘 누군가의 말을 끝까지 들었던 순간이 있었나요?"
    const val WEEKLY_SUMMARY = "네 편의 일기 중 세 편이 ‘듣기’와 ‘걷기’로 하루를 정리했어요. 주 초반보다 문장이 차분해졌어요."
    const val WEEKLY_MOOD = "차분함이 늘었어요"

    /** 3.14, fixed, no ✦. */
    val exampleQuestions = listOf(
        "오늘 가장 오래 머문 생각은 무엇이었나요?",
        "최근 누군가에게 고마웠던 순간이 있나요?",
        "내일의 나에게 한마디 한다면?",
    )
}
