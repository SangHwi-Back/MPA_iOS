@file:OptIn(ExperimentalTime::class)

package com.example.mpa_android.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.mpa_android.data.JournalRepository
import com.example.mpa_android.model.Journal
import dagger.hilt.android.lifecycle.HiltViewModel
import java.time.LocalDate
import javax.inject.Inject
import kotlin.time.Clock
import kotlin.time.ExperimentalTime
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

@OptIn(ExperimentalTime::class)
@HiltViewModel
class JournalViewModel @Inject constructor(
    private val repository: JournalRepository,
) : ViewModel() {

    val journals: StateFlow<List<Journal>> = repository.journals.stateIn(
        scope = viewModelScope,
        started = SharingStarted.Eagerly,
        initialValue = emptyList(),
    )

    fun addJournal(
        day: LocalDate = LocalDate.now(),
        title: String = "",
        body: String = "",
        prompt: String? = null,
    ): Journal {
        val newJournal = Journal(
            day = day,
            createdAt = Clock.System.now(),
            title = title,
            body = body,
            prompt = prompt,
        )
        viewModelScope.launch { repository.save(newJournal) }
        return newJournal
    }
}
