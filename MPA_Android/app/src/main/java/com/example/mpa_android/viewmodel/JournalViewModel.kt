// [NO AC] Spec: specs/journal/SCREEN_SPEC.md
@file:OptIn(ExperimentalTime::class)

package com.example.mpa_android.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.android.identity.util.UUID
import com.example.mpa_android.data.InMemoryJournalPreferences
import com.example.mpa_android.data.JournalPreferences
import com.example.mpa_android.data.JournalRepository
import com.example.mpa_android.model.Journal
import dagger.hilt.android.lifecycle.HiltViewModel
import java.time.LocalDate
import javax.inject.Inject
import kotlin.time.Clock
import kotlin.time.ExperimentalTime
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

enum class JournalViewMode { LIST, CALENDAR }

private const val MAX_RECENT_SEARCHES = 5

@OptIn(ExperimentalTime::class)
@HiltViewModel
class JournalViewModel @Inject constructor(
    private val repository: JournalRepository,
    private val preferences: JournalPreferences = InMemoryJournalPreferences(),
) : ViewModel() {

    val journals: StateFlow<List<Journal>> = repository.journals.stateIn(
        scope = viewModelScope,
        started = SharingStarted.Eagerly,
        initialValue = emptyList(),
    )

    /** Ids hidden from the list: the entry waiting on the undo snackbar and entries being deleted. */
    private val hiddenIds = MutableStateFlow<Set<UUID>>(emptySet())

    private val _pendingDeletion = MutableStateFlow<Journal?>(null)

    /** The entry the undo snackbar is currently offering to restore. */
    val pendingDeletion: StateFlow<Journal?> = _pendingDeletion.asStateFlow()

    val visibleJournals: StateFlow<List<Journal>> = combine(journals, hiddenIds) { all, hidden ->
        all.filterNot { it.id in hidden }
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.Eagerly,
        initialValue = emptyList(),
    )

    private val _viewMode = MutableStateFlow(
        JournalViewMode.entries.firstOrNull { it.name == preferences.viewMode } ?: JournalViewMode.LIST,
    )

    /** The last choice is restored the next time the app opens. */
    val viewMode: StateFlow<JournalViewMode> = _viewMode.asStateFlow()

    private val _recentSearches = MutableStateFlow(preferences.recentSearches)
    val recentSearches: StateFlow<List<String>> = _recentSearches.asStateFlow()

    /** The entry written on [day], if any. */
    fun journal(on: LocalDate): Journal? = visibleJournals.value.firstOrNull { it.day == on }

    /** Stores a new journal, or saves the changes made to one that is already stored. */
    fun save(journal: Journal) {
        viewModelScope.launch { repository.save(journal) }
    }

    /** Creates a journal for [day], or updates the title and body of the one already written that day. */
    fun addJournal(
        day: LocalDate = LocalDate.now(),
        title: String = "",
        body: String = "",
        prompt: String? = null,
    ): Journal {
        val journal = journals.value.firstOrNull { it.day == day }
            ?.copy(title = title, body = body)
            ?: Journal(
                day = day,
                createdAt = Clock.System.now(),
                title = title,
                body = body,
                prompt = prompt,
            )
        save(journal)
        return journal
    }

    fun setViewMode(mode: JournalViewMode) {
        _viewMode.value = mode
        preferences.viewMode = mode.name
    }

    /** Hides the entry and offers undo. A previous pending deletion becomes permanent. */
    fun deleteJournal(journal: Journal) {
        commitDeletion()
        hiddenIds.update { it + journal.id }
        _pendingDeletion.value = journal
    }

    fun undoDeletion() {
        val journal = _pendingDeletion.value ?: return
        _pendingDeletion.value = null
        hiddenIds.update { it - journal.id }
    }

    /** Runs when the snackbar goes away. The entry stays hidden until the row is gone from the database. */
    fun commitDeletion() {
        val journal = _pendingDeletion.value ?: return
        _pendingDeletion.value = null
        viewModelScope.launch {
            repository.delete(journal.id)
            hiddenIds.update { it - journal.id }
        }
    }

    fun addRecentSearch(query: String) {
        val trimmed = query.trim()
        if (trimmed.isEmpty()) return
        storeRecentSearches((listOf(trimmed) + _recentSearches.value.filterNot { it == trimmed }).take(MAX_RECENT_SEARCHES))
    }

    fun removeRecentSearch(query: String) {
        storeRecentSearches(_recentSearches.value.filterNot { it == query })
    }

    private fun storeRecentSearches(searches: List<String>) {
        _recentSearches.value = searches
        preferences.recentSearches = searches
    }
}
