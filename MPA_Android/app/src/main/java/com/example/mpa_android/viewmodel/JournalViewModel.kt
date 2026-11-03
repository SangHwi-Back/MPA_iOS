package com.example.mpa_android.viewmodel

import androidx.lifecycle.ViewModel
import com.example.mpa_android.model.Journal
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.time.LocalDate

class JournalViewModel : ViewModel() {
    private val _journals = MutableStateFlow(listOf(Journal.sample))
    val journals: StateFlow<List<Journal>> = _journals.asStateFlow()
}