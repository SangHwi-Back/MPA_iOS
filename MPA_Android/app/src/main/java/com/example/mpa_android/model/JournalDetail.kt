// [NO AC] Spec: specs/journal/SCREEN_SPEC.md
@file:OptIn(ExperimentalTime::class)

package com.example.mpa_android.model

import com.android.identity.util.UUID
import java.time.LocalDate
import kotlin.time.Clock
import kotlin.time.ExperimentalTime
import kotlinx.coroutines.delay

/** Number of principle color stages (0 = most recent … 4 = oldest). */
const val PRINCIPLE_STAGE_COUNT = 5

/** Principle color stage per keyword, in quintiles of each keyword's last appearance. */
fun List<Journal>.keywordStages(): Map<String, Int> {
    val lastSeen = mutableMapOf<String, LocalDate>()
    forEach { journal ->
        journal.visibleKeywords.forEach { keyword ->
            val current = lastSeen[keyword.name]
            if (current == null || journal.day > current) lastSeen[keyword.name] = journal.day
        }
    }
    val ordered = lastSeen.entries.sortedWith(
        compareByDescending<Map.Entry<String, LocalDate>> { it.value }.thenBy { it.key },
    )
    return ordered.withIndex().associate { (index, entry) -> entry.key to index * PRINCIPLE_STAGE_COUNT / ordered.size }
}

/** Everything the keyword sheet shows for one keyword. */
data class JournalKeywordSummary(
    val name: String,
    val stage: Int,
    /** Entries where the keyword was extracted and not excluded, newest first. */
    val entries: List<Journal>,
    val firstSeen: LocalDate,
    /** True when the keyword is one of the current top principles. */
    val isPrinciple: Boolean,
)

/** Writes the "이 일기에 대한 AI 한마디" text for an entry. Throws when generation fails. */
fun interface JournalCommentGenerator {
    suspend fun comment(journalId: UUID, title: String, body: String): AIText
}

/** Returns a fixed comment after a short delay. Replace with Gemini Nano or the API key provider. */
class StubJournalCommentGenerator(
    private val engine: AIEngine = AIEngine.GEMINI_NANO,
) : JournalCommentGenerator {
    override suspend fun comment(journalId: UUID, title: String, body: String): AIText {
        delay(1_200)
        return AIText(
            text = "듣는 쪽을 택하자 문제의 진짜 모양이 보였네요. 다음 회의에는 첫 질문 하나를 미리 적어 가 보는 건 어때요?",
            engine = engine,
            generatedAt = Clock.System.now(),
            sourceJournalIds = listOf(journalId),
        )
    }
}

/** Local check that swaps the AI comment for the help resource card. */
object JournalSensitiveContent {
    val phrases = listOf("죽고 싶", "죽고싶", "자살", "자해", "사라지고 싶", "살기 싫", "살고 싶지 않")

    fun isSensitive(text: String): Boolean {
        val compact = text.replace(" ", "")
        return phrases.any { compact.contains(it.replace(" ", "")) }
    }
}
