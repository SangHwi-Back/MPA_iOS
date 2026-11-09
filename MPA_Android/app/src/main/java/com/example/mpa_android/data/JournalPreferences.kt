package com.example.mpa_android.data

import android.content.SharedPreferences
import androidx.core.content.edit
import javax.inject.Inject
import org.json.JSONArray

/** Device-local UI state for the 기록 tab. */
interface JournalPreferences {
    var viewMode: String?
    var recentSearches: List<String>
}

class InMemoryJournalPreferences : JournalPreferences {
    override var viewMode: String? = null
    override var recentSearches: List<String> = emptyList()
}

class SharedJournalPreferences @Inject constructor(
    private val preferences: SharedPreferences,
) : JournalPreferences {

    override var viewMode: String?
        get() = preferences.getString(KEY_VIEW_MODE, null)
        set(value) = preferences.edit { putString(KEY_VIEW_MODE, value) }

    override var recentSearches: List<String>
        get() {
            val stored = JSONArray(preferences.getString(KEY_RECENT_SEARCHES, "[]"))
            return List(stored.length()) { stored.getString(it) }
        }
        set(value) = preferences.edit { putString(KEY_RECENT_SEARCHES, JSONArray(value).toString()) }

    private companion object {
        const val KEY_VIEW_MODE = "journal.viewMode"
        const val KEY_RECENT_SEARCHES = "journal.recentSearches"
    }
}
