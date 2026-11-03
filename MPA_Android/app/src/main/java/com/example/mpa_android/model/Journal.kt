@file:OptIn(ExperimentalTime::class)

package com.example.mpa_android.model

import com.android.identity.util.UUID
import java.time.LocalDate
import kotlin.time.Clock
import kotlin.time.Duration
import kotlin.time.ExperimentalTime
import kotlin.time.Instant

data class Journal(
    val id: UUID = UUID.randomUUID(),

    /** The day this entry belongs to. Changeable from the editor. Several entries per day allowed. */
    val day: LocalDate,

    /** When the entry was first saved (shown as "오후 9:40" in detail). */
    val createdAt: Instant,

    /** Set only after the entry is edited post-creation ("마지막 수정 …" shown only when non-null). */
    val editedAt: Instant? = null,

    /** Optional. Blank means "use the first line of the body" (see [displayTitle]). */
    val title: String = "",

    val body: String = "",

    /** The "글감" question the entry was started from. Stored, not shown in detail. */
    val prompt: String? = null,

    /** Ordered as shown in the editor grid (drag to reorder). Max [MAX_PHOTOS]. */
    val photos: List<JournalPhoto> = emptyList(),

    /** AI-extracted plus user-added keywords, including ones the user excluded. */
    val keywords: List<JournalKeyword> = emptyList(),

    val analysisState: AnalysisState = AnalysisState.NotAnalyzed,

    /** Cached "이 일기에 대한 AI 한마디". Generated on first expand, cleared when the entry is edited. */
    val aiComment: AIText? = null,
) {

    // ---- Derived values ----

    /** Title, or the first non-blank line of the body when the title is blank. */
    val displayTitle: String
        get() = title.trim().ifEmpty {
            body.lineSequence().map { it.trim() }.firstOrNull { it.isNotEmpty() }.orEmpty()
        }

    /** Body text for the 2-line list preview. Skips the first line when it became the title. */
    val previewText: String
        get() {
            val lines = body.lineSequence().map { it.trim() }.filter { it.isNotEmpty() }.toList()
            val rest = if (title.isBlank()) lines.drop(1) else lines
            return rest.joinToString(" ")
        }

    /** An entry with no title, body, or photos is discarded when the editor closes. */
    val isEmpty: Boolean
        get() = title.isBlank() && body.isBlank() && photos.isEmpty()

    val isEdited: Boolean
        get() = editedAt != null

    /** First photo, used as the list thumbnail ("+N" badge = photos.size - 1). */
    val thumbnail: JournalPhoto?
        get() = photos.firstOrNull()

    /** Keywords to display: not excluded, most influential first. */
    val visibleKeywords: List<JournalKeyword>
        get() = keywords.filterNot { it.isExcluded }.sortedByDescending { it.influence }

    // ---- Mutations (return a new copy) ----

    /** Apply an edit to the text. Invalidates AI output so it is regenerated. */
    fun edited(title: String = this.title, body: String = this.body, at: Instant = Clock.System.now()): Journal =
        copy(
            title = title,
            body = body,
            editedAt = at,
            aiComment = null,
            analysisState = AnalysisState.NotAnalyzed,
        )

    /**
     * Replace AI keywords after (re)analysis while keeping the user's choices:
     * user-added keywords stay, and keywords the user excluded stay excluded.
     */
    fun withAnalysis(extracted: List<JournalKeyword>, at: Instant = Clock.System.now()): Journal {
        val excludedNames = keywords.filter { it.isExcluded }.map { it.name }.toSet()
        val userAdded = keywords.filter { it.source == KeywordSource.USER }
        val userNames = userAdded.map { it.name }.toSet()
        val ai = extracted
            .filterNot { it.name in userNames }
            .map { it.copy(isExcluded = it.name in excludedNames) }
        return copy(keywords = userAdded + ai, analysisState = AnalysisState.Analyzed(at))
    }

    /** "✕" on a keyword chip in the editor. */
    fun withoutKeyword(name: String): Journal {
        val target = keywords.firstOrNull { it.name == name } ?: return this
        val updated = if (target.source == KeywordSource.USER) {
            keywords - target
        } else {
            keywords.map { if (it.name == name) it.copy(isExcluded = true) else it }
        }
        return copy(keywords = updated)
    }

    /** "+ 추가" in the editor. */
    fun withKeyword(name: String): Journal {
        val trimmed = name.trim()
        if (trimmed.isEmpty()) return this
        return if (keywords.any { it.name == trimmed }) {
            copy(keywords = keywords.map { if (it.name == trimmed) it.copy(isExcluded = false) else it })
        } else {
            copy(keywords = keywords + JournalKeyword(trimmed, KeywordSource.USER, influence = 1.0))
        }
    }

    companion object {
        const val MAX_PHOTOS = 10
        /** Keyword chips shown on a list item. */
        const val MAX_KEYWORDS_IN_LIST = 2
        /** Keyword chips shown in detail. */
        const val MAX_KEYWORDS_IN_DETAIL = 5
        /** Recommended keyword length (characters). */
        val KEYWORD_LENGTH = 2..4

        /** Design example data. */
        val sample: Journal by lazy {
            val created = Instant.parse("2026-10-27T12:40:00Z") // 21:40 KST
            Journal(
                day = LocalDate.of(2026, 10, 27),
                createdAt = created,
                editedAt = created.plus(Duration.parse("1h")),
                title = "회의에서 말을 끊지 않기",
                body = """
                    오늘 주간 회의에서 끝까지 들어 보기로 마음먹었다. 민지 씨가 일정 이야기를 꺼냈을 때, 평소 같았으면 중간에 끼어들어 해결책부터 말했을 거다.

                    이번에는 말이 끝날 때까지 기다렸다. 그랬더니 문제는 일정이 아니라 리뷰가 한 사람에게 몰려 있다는 데 있었다.

                    내가 하려던 질문이 달라졌다. 다음 회의에도 먼저 묻고, 그다음에 말해야겠다.
                """.trimIndent(),
                prompt = "오늘 누군가의 말을 끝까지 들었던 순간이 있었나요?",
                photos = listOf(
                    JournalPhoto(fileName = "whiteboard.jpg", caption = "회의실 화이트보드"),
                    JournalPhoto(fileName = "coffee.jpg", caption = "회의 끝나고 마신 커피"),
                ),
                keywords = listOf(
                    JournalKeyword("경청", KeywordSource.AI, influence = 0.92),
                    JournalKeyword("솔직함", KeywordSource.AI, influence = 0.61),
                ),
                analysisState = AnalysisState.Analyzed(created.plus(Duration.parse("1h"))),
            )
        }
    }
}

data class JournalPhoto(
    val id: UUID = UUID.randomUUID(),
    /** File name inside the app's private photo directory (never a MediaStore reference). */
    val fileName: String,
    /** Edited from photo detail. Not shown on thumbnails. Never sent to an external API. */
    val caption: String = "",
)

data class JournalKeyword(
    /** 2–4 characters recommended (e.g. "경청"). */
    val name: String,
    val source: KeywordSource,
    /**
     * 0..1. How strongly this entry expresses the keyword. Used to order chips and
     * to pick the "top 3 entries" in the principle bubble menu.
     */
    val influence: Double,
    /** AI keyword the user removed with "✕". Kept so re-analysis does not bring it back. */
    val isExcluded: Boolean = false,
)

enum class KeywordSource { AI, USER }

sealed interface AnalysisState {
    /** Not analyzed yet (new or edited). Keyword section hidden. */
    data object NotAnalyzed : AnalysisState
    /** "키워드를 찾는 중…" with skeleton chips. */
    data object Analyzing : AnalysisState
    data class Analyzed(val at: Instant) : AnalysisState
    data object Failed : AnalysisState
    /** No on-device AI and no API key ("일기 앱 모드"). Keyword section hidden. */
    data object Unavailable : AnalysisState
}

/** Any AI-generated text (AI 한마디, 오늘의 조언, 주간 요약, 원칙 정의). */
data class AIText(
    val text: String,
    val engine: AIEngine,
    val generatedAt: Instant,
    /** Entries the text was based on (shown as source chips where the design has them). */
    val sourceJournalIds: List<UUID> = emptyList(),
    val feedback: AIFeedback? = null,
)

enum class AIFeedback { HELPFUL, NOT_HELPFUL }

enum class AIEngine(
    /** Source label shown under AI content. */
    val sourceLabel: String,
    val isOnDevice: Boolean,
) {
    APPLE_INTELLIGENCE("✦ Apple Intelligence로 기기에서 생성됨", isOnDevice = true),
    GEMINI_NANO("✦ 기기 내 AI로 생성됨", isOnDevice = true),
    GEMINI_API_KEY("✦ Gemini (내 API 키)", isOnDevice = false),
    OPENAI_API_KEY("✦ OpenAI (내 API 키)", isOnDevice = false),
}
