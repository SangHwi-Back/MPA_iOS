package com.example.mpa_android.viewmodel

import androidx.lifecycle.ViewModel
import com.example.mpa_android.model.Journal

class JournalViewModel : ViewModel() {
    val journals = mutableListOf(Journal.sample)
}