// [NO AC] Spec: specs/journal/SCREEN_SPEC.md
@file:OptIn(ExperimentalCoroutinesApi::class, ExperimentalTime::class)

package com.example.mpa_android.viewmodel

import androidx.lifecycle.SavedStateHandle
import com.android.identity.util.UUID
import com.example.mpa_android.data.JournalRepository
import com.example.mpa_android.model.AIEngine
import com.example.mpa_android.model.AIFeedback
import com.example.mpa_android.model.AIText
import com.example.mpa_android.model.AnalysisState
import com.example.mpa_android.model.Journal
import com.example.mpa_android.model.JournalCommentGenerator
import com.example.mpa_android.model.JournalKeyword
import com.example.mpa_android.model.KeywordSource
import java.time.LocalDate
import java.time.ZoneId
import kotlin.time.ExperimentalTime
import kotlin.time.Instant
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

private val CREATED: Instant = Instant.parse("2026-10-27T12:40:00Z")
private val SEOUL: ZoneId = ZoneId.of("Asia/Seoul")

private class DetailFakeRepository(initial: List<Journal>) : JournalRepository {
    override val journals = MutableStateFlow(initial)

    override suspend fun save(journal: Journal) {
        val current = journals.value
        journals.value = if (current.any { it.id == journal.id }) {
            current.map { if (it.id == journal.id) journal else it }
        } else {
            current + journal
        }
    }

    override suspend fun delete(id: UUID) {
        journals.value = journals.value.filterNot { it.id == id }
    }
}

private class DetailFakeCommentGenerator : JournalCommentGenerator {
    var result: Result<AIText> = Result.success(aiText("새 코멘트"))
    var calls = 0

    override suspend fun comment(journalId: UUID, title: String, body: String): AIText {
        calls += 1
        return result.getOrThrow()
    }
}

private fun aiText(text: String) = AIText(text = text, engine = AIEngine.GEMINI_NANO, generatedAt = CREATED)

private fun keyword(name: String, influence: Double = 1.0, excluded: Boolean = false) =
    JournalKeyword(name, KeywordSource.AI, influence, isExcluded = excluded)

private fun journal(
    day: LocalDate = LocalDate.of(2026, 10, 27),
    body: String = "",
    keywords: List<JournalKeyword> = emptyList(),
    analysisState: AnalysisState = AnalysisState.NotAnalyzed,
    aiComment: AIText? = null,
) = Journal(
    day = day,
    createdAt = CREATED,
    body = body,
    keywords = keywords,
    analysisState = analysisState,
    aiComment = aiComment,
)

class JournalDetailViewModelTest {

    private val dispatcher = StandardTestDispatcher()
    private val generator = DetailFakeCommentGenerator()
    private lateinit var repository: DetailFakeRepository
    private lateinit var viewModel: JournalDetailViewModel

    private val state get() = viewModel.uiState.value

    @Before
    fun setUp() {
        Dispatchers.setMain(dispatcher)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    private fun open(entry: Journal, others: List<Journal> = emptyList()) {
        repository = DetailFakeRepository(listOf(entry) + others)
        viewModel = JournalDetailViewModel(
            repository,
            generator,
            SavedStateHandle(mapOf(JournalDetailViewModel.ARG_JOURNAL_ID to entry.id.toString())),
        )
    }

    // ---- Text ----

    @Test
    fun dateTexts() {
        assertEquals(
            "2026년 10월 27일 화요일 · 오후 9:40",
            JournalDetailViewModel.dateLine(LocalDate.of(2026, 10, 27), CREATED, SEOUL),
        )
        assertEquals("10월 27일", JournalDetailViewModel.shortDate(LocalDate.of(2026, 10, 27)))
        assertEquals(
            "마지막 수정 10월 27일 오후 9:52",
            JournalDetailViewModel.editedLine(Instant.parse("2026-10-27T12:52:00Z"), SEOUL),
        )
    }

    @Test
    fun paragraphsSplitOnBlankLines() {
        assertEquals(listOf("a", "b", "c"), JournalDetailViewModel.paragraphs("a\n\nb\n\n\nc"))
    }

    // ---- Keyword row ----

    @Test
    fun keywordRowFollowsAnalysisState() {
        assertEquals(JournalKeywordRow.Skeleton, JournalDetailViewModel.keywordRow(journal(analysisState = AnalysisState.Analyzing)))
        assertEquals(JournalKeywordRow.Hidden, JournalDetailViewModel.keywordRow(journal(analysisState = AnalysisState.NotAnalyzed)))
    }

    @Test
    fun keywordRowShowsFiveMostInfluentialVisibleKeywords() {
        val keywords = listOf(
            keyword("다", 0.7), keyword("가", 0.9), keyword("마", 0.5), keyword("나", 0.8),
            keyword("라", 0.6), keyword("바", 0.4), keyword("제외", 1.0, excluded = true),
        )
        val row = JournalDetailViewModel.keywordRow(journal(keywords = keywords, analysisState = AnalysisState.Analyzed(CREATED)))

        assertEquals(listOf("가", "나", "다", "라", "마"), (row as JournalKeywordRow.Chips).keywords.map { it.name })
    }

    @Test
    fun unavailableHidesAI() = runTest(dispatcher) {
        open(journal(keywords = listOf(keyword("경청")), analysisState = AnalysisState.Unavailable))
        advanceUntilIdle()

        assertFalse(state.isAIAvailable)
        assertEquals(JournalKeywordRow.Hidden, state.keywordRow)
    }

    // ---- Loading ----

    @Test
    fun loadsEntryFromRepository() = runTest(dispatcher) {
        val entry = journal()
        open(entry, others = listOf(journal(day = LocalDate.of(2026, 10, 20))))
        advanceUntilIdle()

        assertEquals(entry.id, state.journal?.id)
        assertEquals(2, state.allJournals.size)
    }

    // ---- AI comment ----

    @Test
    fun firstExpandGeneratesOnce() = runTest(dispatcher) {
        open(journal())
        advanceUntilIdle()

        viewModel.toggleComment()
        advanceUntilIdle()
        assertEquals(JournalCommentPhase.Loaded(aiText("새 코멘트")), state.commentPhase)
        assertTrue(state.revealsCommentByWord)
        assertEquals("새 코멘트", repository.journals.value.single().aiComment?.text)

        viewModel.toggleComment()
        viewModel.toggleComment()
        advanceUntilIdle()
        assertTrue(state.isCommentExpanded)
        assertEquals(1, generator.calls)
    }

    @Test
    fun cachedCommentIsNotRegenerated() = runTest(dispatcher) {
        open(journal(aiComment = aiText("캐시")))
        advanceUntilIdle()
        assertEquals(JournalCommentPhase.Loaded(aiText("캐시")), state.commentPhase)

        viewModel.toggleComment()
        advanceUntilIdle()
        assertEquals(0, generator.calls)
        assertFalse(state.revealsCommentByWord)
    }

    @Test
    fun failureThenRetry() = runTest(dispatcher) {
        generator.result = Result.failure(IllegalStateException("model unavailable"))
        open(journal())
        advanceUntilIdle()

        viewModel.toggleComment()
        advanceUntilIdle()
        assertEquals(JournalCommentPhase.Failed, state.commentPhase)

        generator.result = Result.success(aiText("다시"))
        viewModel.generateComment()
        advanceUntilIdle()
        assertEquals(JournalCommentPhase.Loaded(aiText("다시")), state.commentPhase)
    }

    @Test
    fun feedbackTogglesOff() = runTest(dispatcher) {
        open(journal(aiComment = aiText("코멘트")))
        advanceUntilIdle()

        viewModel.toggleFeedback(AIFeedback.HELPFUL)
        advanceUntilIdle()
        assertEquals(AIFeedback.HELPFUL, state.journal?.aiComment?.feedback)

        viewModel.toggleFeedback(AIFeedback.HELPFUL)
        advanceUntilIdle()
        assertNull(state.journal?.aiComment?.feedback)
    }

    @Test
    fun regenerateCallsGeneratorAgain() = runTest(dispatcher) {
        open(journal(aiComment = aiText("이전")))
        advanceUntilIdle()

        viewModel.regenerateComment()
        advanceUntilIdle()

        assertEquals(1, generator.calls)
        assertEquals("새 코멘트", state.journal?.aiComment?.text)
    }

    // ---- Keyword sheet ----

    @Test
    fun keywordSummaryListsMatchingEntriesNewestFirst() {
        val entries = listOf(
            journal(day = LocalDate.of(2026, 10, 20), keywords = listOf(keyword("경청"))),
            journal(day = LocalDate.of(2026, 9, 14), keywords = listOf(keyword("경청"))),
            journal(day = LocalDate.of(2026, 10, 27), keywords = listOf(keyword("경청"))),
            journal(day = LocalDate.of(2026, 10, 26), keywords = listOf(keyword("경청", excluded = true))),
        )

        val summary = JournalDetailViewModel.keywordSummary("경청", entries, mapOf("경청" to 1))!!

        assertEquals(
            listOf(LocalDate.of(2026, 10, 27), LocalDate.of(2026, 10, 20), LocalDate.of(2026, 9, 14)),
            summary.entries.map { it.day },
        )
        assertEquals(LocalDate.of(2026, 9, 14), summary.firstSeen)
        assertEquals(1, summary.stage)
        assertTrue(summary.isPrinciple)
        assertNull(JournalDetailViewModel.keywordSummary("없음", entries, emptyMap()))
    }

    @Test
    fun topPrinciplesDropsTheRarestKeyword() {
        val common = listOf("가", "나", "다", "라", "마").flatMap { name ->
            listOf(
                journal(day = LocalDate.of(2026, 10, 20), keywords = listOf(keyword(name))),
                journal(day = LocalDate.of(2026, 10, 21), keywords = listOf(keyword(name))),
            )
        }
        val entries = common + journal(day = LocalDate.of(2026, 10, 27), keywords = listOf(keyword("희귀")))

        val principles = JournalDetailViewModel.topPrinciples(entries)

        assertEquals(JournalDetailViewModel.PRINCIPLE_COUNT, principles.size)
        assertFalse("희귀" in principles)
    }

    @Test
    fun presentKeywordBuildsSummary() = runTest(dispatcher) {
        open(journal(keywords = listOf(keyword("경청"))))
        advanceUntilIdle()

        viewModel.presentKeyword("경청")
        advanceUntilIdle()
        assertEquals("경청", state.presentedSummary?.name)

        viewModel.presentKeyword(null)
        advanceUntilIdle()
        assertNull(state.presentedSummary)
    }

    // ---- Other ----

    @Test
    fun sensitiveContentDetection() = runTest(dispatcher) {
        open(journal(body = "요즘 죽고 싶다는 생각이 들었다"))
        advanceUntilIdle()
        assertTrue(state.isSensitive)
    }

    @Test
    fun changeDaySavesNewDay() = runTest(dispatcher) {
        open(journal())
        advanceUntilIdle()

        viewModel.changeDay(LocalDate.of(2026, 10, 25))
        advanceUntilIdle()

        assertEquals(LocalDate.of(2026, 10, 25), repository.journals.value.single().day)
    }
}
