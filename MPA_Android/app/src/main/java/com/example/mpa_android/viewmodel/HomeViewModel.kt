// [NO AC] Spec: specs/home/SCREEN_SPEC.md
@file:OptIn(ExperimentalTime::class)

package com.example.mpa_android.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.android.identity.util.UUID
import com.example.mpa_android.data.JournalRepository
import com.example.mpa_android.model.AIFeedback
import com.example.mpa_android.model.AIText
import com.example.mpa_android.model.HomeAIGenerator
import com.example.mpa_android.model.HomeAIPhase
import com.example.mpa_android.model.HomeAIStatus
import com.example.mpa_android.model.HomeLayout
import com.example.mpa_android.model.HomePrinciple
import com.example.mpa_android.model.HomeWeekDay
import com.example.mpa_android.model.Journal
import com.example.mpa_android.model.JournalSensitiveContent
import dagger.hilt.android.lifecycle.HiltViewModel
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import java.time.temporal.TemporalAdjusters
import java.util.Locale
import javax.inject.Inject
import kotlin.math.max
import kotlin.math.min
import kotlin.time.Clock
import kotlin.time.ExperimentalTime
import kotlin.time.Instant
import kotlin.time.toJavaInstant
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/** Everything 오늘 shows. Derived values are computed here so the screen and the previews share them. */
data class HomeUiState(
    val entries: List<Journal> = emptyList(),
    val aiStatus: HomeAIStatus = HomeAIStatus.Available(com.example.mpa_android.model.AIEngine.GEMINI_NANO),
    val now: LocalDateTime = LocalDateTime.now(),
    val advicePhase: HomeAIPhase = HomeAIPhase.Idle,
    val promptPhase: HomeAIPhase = HomeAIPhase.Idle,
    val summaryPhase: HomeAIPhase = HomeAIPhase.Idle,
    /** True only while a freshly generated advice is revealed word by word. */
    val revealsAdviceByWord: Boolean = false,
    val isSummaryExpanded: Boolean = false,
    val isAlertPresented: Boolean = false,
    /** Week strip paging (0 = this week, -1 = last week …). */
    val weekOffset: Int = 0,
) {
    val today: LocalDate get() = now.toLocalDate()

    val layout: HomeLayout get() = HomeViewModel.layout(entries.size, aiStatus.isAvailable)

    val greeting: String get() = HomeViewModel.greeting(now.hour, isFirstRun = entries.isEmpty())

    val dateLine: String get() = HomeViewModel.dateLine(today)

    /** The latest entry written for today, if any. */
    val todayEntry: Journal? get() = entries.filter { it.day == today }.maxByOrNull { it.createdAt }

    val principles: List<HomePrinciple> get() = HomeViewModel.principles(entries)

    val weekDays: List<HomeWeekDay> get() = HomeViewModel.weekDays(today, weekOffset, entries)

    val recentEntries: List<Journal> get() = HomeViewModel.newestFirst(entries).take(HomeViewModel.RECENT_COUNT)

    val thisWeekEntries: List<Journal>
        get() {
            val monday = today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
            return entries.filter { !it.day.isBefore(monday) && !it.day.isAfter(monday.plusDays(6)) }
        }

    /** 3.11: hidden with no entries this week or fewer than 3 entries overall. */
    val showsWeeklySummary: Boolean
        get() = aiStatus.isAvailable && entries.size >= HomeViewModel.PRINCIPLE_THRESHOLD && thisWeekEntries.isNotEmpty()

    /** "10월 26일–30일 · 일기 4개". */
    val weeklyRangeLine: String
        get() {
            val days = thisWeekEntries.map { it.day }
            val first = days.minOrNull() ?: return ""
            val last = days.max()
            return HomeViewModel.rangeText(first, last) + " · 일기 ${thisWeekEntries.size}개"
        }

    /** The entries the next advice is based on: newest 1–3, so 1–2 entries give that many chips. */
    val adviceSourceIds: List<UUID>
        get() = HomeViewModel.newestFirst(entries).take(HomeViewModel.MAX_ADVICE_SOURCES).map { it.id }

    /** 3.3 / Part B 7: the local check runs on the entries the advice would read. */
    val isSensitive: Boolean
        get() = HomeViewModel.newestFirst(entries).take(HomeViewModel.MAX_ADVICE_SOURCES)
            .any { JournalSensitiveContent.isSensitive(it.title + " " + it.body) }

    /** Entries a text was based on, oldest first (3.4). */
    fun sources(text: AIText?): List<Journal> =
        text?.sourceJournalIds.orEmpty()
            .mapNotNull { id -> entries.firstOrNull { it.id == id } }
            .sortedBy { it.day }
}

@HiltViewModel
class HomeViewModel @Inject constructor(
    repository: JournalRepository,
    private val generator: HomeAIGenerator,
) : ViewModel() {

    private val local = MutableStateFlow(HomeUiState())
    private var adviceFailures = 0
    private var summaryFailures = 0

    val uiState: StateFlow<HomeUiState> = combine(repository.journals, local) { journals, state ->
        state.copy(entries = journals)
    }.stateIn(viewModelScope, SharingStarted.Eagerly, HomeUiState())

    init {
        // New entries change the sources and the progress state, so the cards are written again.
        viewModelScope.launch {
            repository.journals.map { list -> list.map { it.id } }.distinctUntilChanged().collect {
                local.update { state ->
                    state.copy(
                        now = LocalDateTime.now(),
                        advicePhase = if (state.advicePhase is HomeAIPhase.Loaded || state.advicePhase == HomeAIPhase.Sensitive) HomeAIPhase.Idle else state.advicePhase,
                        summaryPhase = if (state.summaryPhase is HomeAIPhase.Loaded) HomeAIPhase.Idle else state.summaryPhase,
                    )
                }
                load()
            }
        }
    }

    fun setAIStatus(status: HomeAIStatus) {
        if (local.value.aiStatus == status) return
        adviceFailures = 0
        summaryFailures = 0
        local.update {
            it.copy(
                aiStatus = status,
                advicePhase = HomeAIPhase.Idle,
                promptPhase = HomeAIPhase.Idle,
                summaryPhase = HomeAIPhase.Idle,
            )
        }
        load()
    }

    /** Starts every AI card the current layout shows that has nothing yet. */
    fun load() {
        val state = uiState.value
        if (!state.aiStatus.isAvailable || state.entries.isEmpty()) return
        if (state.advicePhase == HomeAIPhase.Idle) generateAdvice()
        if (state.todayEntry == null && state.promptPhase == HomeAIPhase.Idle) nextPrompt()
        if (state.showsWeeklySummary && state.summaryPhase == HomeAIPhase.Idle) generateSummary()
    }

    fun generateAdvice() {
        val state = uiState.value
        if (state.isSensitive) {
            local.update { it.copy(advicePhase = HomeAIPhase.Sensitive) }
            return
        }
        val status = state.aiStatus
        val engine = status.engine ?: return
        if (status is HomeAIStatus.KeyError) {
            local.update { it.copy(advicePhase = HomeAIPhase.KeyError) }
            return
        }
        local.update { it.copy(advicePhase = HomeAIPhase.Loading, revealsAdviceByWord = false) }
        viewModelScope.launch {
            runCatching {
                generator.advice(state.adviceSourceIds, isShort = state.entries.size < PRINCIPLE_THRESHOLD, engine = engine)
            }.onSuccess { text ->
                adviceFailures = 0
                local.update { it.copy(advicePhase = HomeAIPhase.Loaded(text), revealsAdviceByWord = true) }
            }.onFailure {
                adviceFailures += 1
                local.update {
                    it.copy(advicePhase = if (adviceFailures >= MAX_FAILURES) HomeAIPhase.Resting else HomeAIPhase.Failed)
                }
            }
        }
    }

    /** ↻: back to the loading state, then a new advice (3.5). */
    fun regenerateAdvice() = generateAdvice()

    /** Fills the chosen thumb; tapping it again clears it (Part B 3). */
    fun toggleFeedback(feedback: AIFeedback) {
        val text = local.value.advicePhase.text ?: return
        val next = text.copy(feedback = if (text.feedback == feedback) null else feedback)
        local.update { it.copy(advicePhase = HomeAIPhase.Loaded(next), revealsAdviceByWord = false) }
    }

    /** "다른 질문": only the question is regenerated (3.6). */
    fun nextPrompt() {
        val engine = uiState.value.aiStatus.engine ?: return
        val previous = local.value.promptPhase
        local.update { it.copy(promptPhase = HomeAIPhase.Loading) }
        viewModelScope.launch {
            runCatching { generator.writingPrompt(engine) }
                .onSuccess { prompt ->
                    val text = AIText(text = prompt, engine = engine, generatedAt = Clock.System.now())
                    local.update { it.copy(promptPhase = HomeAIPhase.Loaded(text)) }
                }
                .onFailure {
                    local.update { it.copy(promptPhase = if (previous is HomeAIPhase.Loaded) previous else HomeAIPhase.Failed) }
                }
        }
    }

    fun generateSummary() {
        val state = uiState.value
        val engine = state.aiStatus.engine ?: return
        if (state.aiStatus is HomeAIStatus.KeyError) {
            local.update { it.copy(summaryPhase = HomeAIPhase.KeyError) }
            return
        }
        local.update { it.copy(summaryPhase = HomeAIPhase.Loading) }
        viewModelScope.launch {
            runCatching { generator.weeklySummary(state.thisWeekEntries.map { it.id }, engine) }
                .onSuccess { text ->
                    summaryFailures = 0
                    local.update { it.copy(summaryPhase = HomeAIPhase.Loaded(text)) }
                }
                .onFailure {
                    summaryFailures += 1
                    local.update {
                        it.copy(summaryPhase = if (summaryFailures >= MAX_FAILURES) HomeAIPhase.Resting else HomeAIPhase.Failed)
                    }
                }
        }
    }

    fun toggleSummary() = local.update { it.copy(isSummaryExpanded = !it.isSummaryExpanded) }

    fun setAlertPresented(isPresented: Boolean) = local.update { it.copy(isAlertPresented = isPresented) }

    /** Swiping right goes back a week; the strip never moves past this week. */
    fun changeWeek(delta: Int) = local.update { it.copy(weekOffset = min(0, it.weekOffset + delta)) }

    companion object {
        const val PRINCIPLE_THRESHOLD = 3
        const val RECENT_COUNT = 5
        const val RELATED_COUNT = 3
        const val MAX_ADVICE_SOURCES = 3
        const val MAX_FAILURES = 3

        private val KOREAN = Locale.KOREAN

        fun layout(entryCount: Int, isAIAvailable: Boolean): HomeLayout = when {
            entryCount == 0 -> HomeLayout.FIRST_RUN
            !isAIAvailable -> HomeLayout.DIARY
            entryCount < PRINCIPLE_THRESHOLD -> HomeLayout.EARLY
            else -> HomeLayout.FULL
        }

        /** 아침 5–11시 / 오후 12–17시 / 저녁 18–21시 / 밤. First run always says "반가워요". */
        fun greeting(hour: Int, isFirstRun: Boolean): String = when {
            isFirstRun -> "반가워요"
            hour in 5..11 -> "좋은 아침이에요"
            hour in 12..17 -> "좋은 오후예요"
            hour in 18..21 -> "좋은 저녁이에요"
            else -> "편안한 밤이에요"
        }

        /** "10월 30일 금요일" (follows the locale). */
        fun dateLine(date: LocalDate, locale: Locale = KOREAN): String =
            if (locale.language == KOREAN.language) {
                date.format(DateTimeFormatter.ofPattern("M월 d일 EEEE", locale))
            } else {
                date.format(DateTimeFormatter.ofPattern("EEEE, MMMM d", locale))
            }

        /** "10월 20일" for source chips. */
        fun chipDate(date: LocalDate): String = date.format(DateTimeFormatter.ofPattern("M월 d일", KOREAN))

        /** "오전 8:12". */
        fun timeText(instant: Instant, zone: ZoneId = ZoneId.systemDefault()): String =
            instant.toJavaInstant().atZone(zone).format(DateTimeFormatter.ofPattern("a h:mm", KOREAN))

        /** "10월 26일–30일", or "10월 30일–11월 1일" across months. */
        fun rangeText(start: LocalDate, end: LocalDate): String {
            if (start == end) return chipDate(start)
            val endText = if (start.month == end.month) "${end.dayOfMonth}일" else chipDate(end)
            return "${chipDate(start)}–$endText"
        }

        fun newestFirst(entries: List<Journal>): List<Journal> =
            entries.sortedWith(compareByDescending<Journal> { it.day }.thenByDescending { it.createdAt })

        /** Top 5 keywords by entry count (ties: most recent first). Stages rank the 5 by last appearance. */
        fun principles(entries: List<Journal>): List<HomePrinciple> {
            val names = JournalDetailViewModel.topPrinciples(entries)
            val lastSeen = names.associateWith { name ->
                entries.filter { entry -> entry.visibleKeywords.any { it.name == name } }.maxOf { it.day }
            }
            val byRecency = names.sortedByDescending { lastSeen.getValue(it) }
            return names.map { name ->
                val matching = entries.mapNotNull { entry ->
                    entry.visibleKeywords.firstOrNull { it.name == name }?.let { entry to it.influence }
                }
                HomePrinciple(
                    name = name,
                    count = matching.size,
                    stage = byRecency.indexOf(name),
                    related = matching
                        .sortedWith(compareByDescending<Pair<Journal, Double>> { it.second }.thenByDescending { it.first.day })
                        .take(RELATED_COUNT)
                        .map { it.first },
                )
            }
        }

        /** Monday-first week containing [today], shifted by [offset] weeks. */
        fun weekDays(today: LocalDate, offset: Int, entries: List<Journal>): List<HomeWeekDay> {
            val monday = today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY)).plusWeeks(offset.toLong())
            val entryDays = entries.map { it.day }.toSet()
            return (0L until 7L).map { index ->
                val day = monday.plusDays(index)
                HomeWeekDay(date = day, hasEntry = day in entryDays, isToday = day == today, isFuture = day.isAfter(today))
            }
        }

        /** Bubble diameter in dp: area ∝ count, minimum 64 (3.8). */
        fun bubbleDiameter(count: Int, maxCount: Int, maxDiameter: Float = 124f, minDiameter: Float = 64f): Float {
            val ratio = kotlin.math.sqrt(count.toDouble() / max(maxCount, 1)).toFloat()
            return max(minDiameter, maxDiameter * ratio)
        }
    }
}
