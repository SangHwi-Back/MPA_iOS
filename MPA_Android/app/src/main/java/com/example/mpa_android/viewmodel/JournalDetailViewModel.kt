// [NO AC] Spec: specs/journal/SCREEN_SPEC.md
@file:OptIn(ExperimentalTime::class)

package com.example.mpa_android.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.mpa_android.data.JournalRepository
import com.example.mpa_android.model.AIFeedback
import com.example.mpa_android.model.AIText
import com.example.mpa_android.model.AnalysisState
import com.example.mpa_android.model.Journal
import com.example.mpa_android.model.JournalCommentGenerator
import com.example.mpa_android.model.JournalKeyword
import com.example.mpa_android.model.JournalKeywordSummary
import com.example.mpa_android.model.JournalSensitiveContent
import com.example.mpa_android.model.keywordStages
import dagger.hilt.android.lifecycle.HiltViewModel
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale
import javax.inject.Inject
import kotlin.time.ExperimentalTime
import kotlin.time.Instant
import kotlin.time.toJavaInstant
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

sealed interface JournalCommentPhase {
    data object Idle : JournalCommentPhase
    data object Loading : JournalCommentPhase
    data class Loaded(val comment: AIText) : JournalCommentPhase
    data object Failed : JournalCommentPhase
}

sealed interface JournalKeywordRow {
    data object Hidden : JournalKeywordRow
    data object Skeleton : JournalKeywordRow
    data class Chips(val keywords: List<JournalKeyword>) : JournalKeywordRow
}

data class JournalDetailUiState(
    /** Null until the entry loads, and after it is deleted. */
    val journal: Journal? = null,
    /** Every entry, for the keyword sheet. */
    val allJournals: List<Journal> = emptyList(),
    val keywordStages: Map<String, Int> = emptyMap(),
    /** Not remembered per entry: every visit starts collapsed. */
    val isCommentExpanded: Boolean = false,
    val commentPhase: JournalCommentPhase = JournalCommentPhase.Idle,
    /** True only right after a fresh generation, so the text fades in word by word once. */
    val revealsCommentByWord: Boolean = false,
    /** The keyword whose sheet is open. */
    val presentedKeyword: String? = null,
) {
    /** No on-device AI and no API key: the keyword row and the AI comment are hidden. */
    val isAIAvailable: Boolean get() = journal?.analysisState != AnalysisState.Unavailable

    val isSensitive: Boolean
        get() = journal?.let { JournalSensitiveContent.isSensitive(it.title + "\n" + it.body) } ?: false

    val hasTitle: Boolean get() = journal?.title?.isNotBlank() == true

    val keywordRow: JournalKeywordRow get() = journal?.let(JournalDetailViewModel::keywordRow) ?: JournalKeywordRow.Hidden

    val presentedSummary: JournalKeywordSummary?
        get() = presentedKeyword?.let { JournalDetailViewModel.keywordSummary(it, allJournals, keywordStages) }
}

/** Transient UI state that is not stored with the entry. */
private data class LocalState(
    val isCommentExpanded: Boolean = false,
    /** Loading or Failed while a request is running or after it failed. Null means "use the cache". */
    val transientPhase: JournalCommentPhase? = null,
    val revealsCommentByWord: Boolean = false,
    val presentedKeyword: String? = null,
)

@HiltViewModel
class JournalDetailViewModel @Inject constructor(
    private val repository: JournalRepository,
    private val generator: JournalCommentGenerator,
    savedStateHandle: SavedStateHandle,
) : ViewModel() {

    private val journalId: String = checkNotNull(savedStateHandle[ARG_JOURNAL_ID])
    private val local = MutableStateFlow(LocalState())

    val uiState: StateFlow<JournalDetailUiState> = combine(repository.journals, local) { all, state ->
        val journal = all.firstOrNull { it.id.toString() == journalId }
        JournalDetailUiState(
            journal = journal,
            allJournals = all,
            keywordStages = all.keywordStages(),
            isCommentExpanded = state.isCommentExpanded,
            commentPhase = state.transientPhase
                ?: journal?.aiComment?.let { JournalCommentPhase.Loaded(it) }
                ?: JournalCommentPhase.Idle,
            revealsCommentByWord = state.revealsCommentByWord,
            presentedKeyword = state.presentedKeyword,
        )
    }.stateIn(viewModelScope, SharingStarted.Eagerly, JournalDetailUiState())

    // ---- AI comment ----

    fun toggleComment() {
        local.update { it.copy(isCommentExpanded = !it.isCommentExpanded) }
        val state = uiState.value
        if (local.value.isCommentExpanded && state.commentPhase == JournalCommentPhase.Idle) generateComment()
    }

    fun generateComment() {
        val journal = uiState.value.journal ?: return
        local.update { it.copy(transientPhase = JournalCommentPhase.Loading, revealsCommentByWord = false) }
        viewModelScope.launch {
            val comment = runCatching { generator.comment(journal.id, journal.title, journal.body) }.getOrNull()
            if (comment == null) {
                local.update { it.copy(transientPhase = JournalCommentPhase.Failed) }
                return@launch
            }
            save { it.copy(aiComment = comment) }
            local.update { it.copy(transientPhase = null, revealsCommentByWord = true) }
        }
    }

    fun regenerateComment() {
        viewModelScope.launch {
            save { it.copy(aiComment = null) }
            generateComment()
        }
    }

    /** Tapping the selected thumb again clears it. */
    fun toggleFeedback(feedback: AIFeedback) {
        val comment = (uiState.value.commentPhase as? JournalCommentPhase.Loaded)?.comment ?: return
        val updated = comment.copy(feedback = if (comment.feedback == feedback) null else feedback)
        local.update { it.copy(revealsCommentByWord = false) }
        viewModelScope.launch { save { it.copy(aiComment = updated) } }
    }

    // ---- Other actions ----

    fun presentKeyword(name: String?) {
        local.update { it.copy(presentedKeyword = name) }
    }

    fun changeDay(day: LocalDate) {
        viewModelScope.launch { save { it.copy(day = day) } }
    }

    private suspend fun save(transform: (Journal) -> Journal) {
        val journal = uiState.value.journal ?: return
        repository.save(transform(journal))
    }

    companion object {
        const val ARG_JOURNAL_ID = "journalId"

        /** Number of keywords that count as the current principles. */
        const val PRINCIPLE_COUNT = 5

        private val KOREAN = Locale.KOREAN

        fun keywordRow(journal: Journal): JournalKeywordRow = when (journal.analysisState) {
            AnalysisState.Analyzing -> JournalKeywordRow.Skeleton
            is AnalysisState.Analyzed -> journal.visibleKeywords
                .take(Journal.MAX_KEYWORDS_IN_DETAIL)
                .takeIf { it.isNotEmpty() }
                ?.let { JournalKeywordRow.Chips(it) }
                ?: JournalKeywordRow.Hidden
            AnalysisState.NotAnalyzed, AnalysisState.Failed, AnalysisState.Unavailable -> JournalKeywordRow.Hidden
        }

        /** Summary for the keyword sheet, built from every entry in the app. */
        fun keywordSummary(name: String, entries: List<Journal>, stages: Map<String, Int>): JournalKeywordSummary? {
            val matching = entries
                .filter { entry -> entry.visibleKeywords.any { it.name == name } }
                .sortedWith(compareByDescending<Journal> { it.day }.thenByDescending { it.createdAt })
            val firstSeen = matching.minOfOrNull { it.day } ?: return null
            return JournalKeywordSummary(
                name = name,
                stage = stages[name] ?: 0,
                entries = matching,
                firstSeen = firstSeen,
                isPrinciple = name in topPrinciples(entries),
            )
        }

        /** The keywords found in the most entries, ties broken by the most recent appearance. */
        fun topPrinciples(entries: List<Journal>): List<String> {
            val counts = mutableMapOf<String, Int>()
            val lastSeen = mutableMapOf<String, LocalDate>()
            entries.forEach { entry ->
                entry.visibleKeywords.map { it.name }.toSet().forEach { name ->
                    counts[name] = (counts[name] ?: 0) + 1
                    lastSeen[name] = maxOf(lastSeen[name] ?: entry.day, entry.day)
                }
            }
            return counts.keys
                .sortedWith(
                    compareByDescending<String> { counts.getValue(it) }
                        .thenByDescending { lastSeen.getValue(it) }
                        .thenBy { it },
                )
                .take(PRINCIPLE_COUNT)
        }

        /** Paragraphs separated by blank lines. */
        fun paragraphs(body: String): List<String> {
            val result = mutableListOf<String>()
            val current = mutableListOf<String>()
            body.lines().forEach { line ->
                if (line.isBlank()) {
                    if (current.isNotEmpty()) result += current.joinToString("\n")
                    current.clear()
                } else {
                    current += line
                }
            }
            if (current.isNotEmpty()) result += current.joinToString("\n")
            return result
        }

        private fun time(instant: Instant, zone: ZoneId) =
            instant.toJavaInstant().atZone(zone)

        /** "2026년 10월 27일 화요일 · 오후 9:40" */
        fun dateLine(day: LocalDate, createdAt: Instant, zone: ZoneId = ZoneId.systemDefault()): String =
            DateTimeFormatter.ofPattern("yyyy년 M월 d일 EEEE", KOREAN).format(day) +
                " · " + DateTimeFormatter.ofPattern("a h:mm", KOREAN).format(time(createdAt, zone))

        /** "10월 27일" */
        fun shortDate(day: LocalDate): String = DateTimeFormatter.ofPattern("M월 d일", KOREAN).format(day)

        /** "마지막 수정 10월 27일 오후 9:52" */
        fun editedLine(editedAt: Instant, zone: ZoneId = ZoneId.systemDefault()): String =
            "마지막 수정 " + DateTimeFormatter.ofPattern("M월 d일 a h:mm", KOREAN).format(time(editedAt, zone))
    }
}
