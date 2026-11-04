@file:OptIn(ExperimentalTime::class)

package com.example.mpa_android.viewmodel

import androidx.lifecycle.ViewModel
import com.example.mpa_android.model.Journal
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.time.LocalDate
import javax.inject.Inject
import kotlin.time.Clock
import kotlin.time.ExperimentalTime

@HiltViewModel
class JournalViewModel @Inject constructor() : ViewModel() {
    private val _journals = MutableStateFlow<List<Journal>>(emptyList())
    val journals: StateFlow<List<Journal>> = _journals.asStateFlow()

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
        _journals.value += newJournal
        return newJournal
    }
}
