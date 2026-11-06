@file:OptIn(ExperimentalTime::class, ExperimentalCoroutinesApi::class)

package com.example.mpa_android.viewmodel

import com.android.identity.util.UUID
import com.example.mpa_android.data.JournalRepository
import com.example.mpa_android.model.Journal
import java.time.LocalDate
import kotlin.time.ExperimentalTime
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

private class FakeJournalRepository : JournalRepository {
    val state = MutableStateFlow<List<Journal>>(emptyList())
    override val journals: Flow<List<Journal>> = state

    override suspend fun save(journal: Journal) {
        state.value += journal
    }

    override suspend fun delete(id: UUID) {
        state.value = state.value.filterNot { it.id == id }
    }
}

class JournalViewModelTest {

    private val dispatcher = StandardTestDispatcher()
    private lateinit var repository: FakeJournalRepository
    private lateinit var viewModel: JournalViewModel

    @Before
    fun setUp() {
        Dispatchers.setMain(dispatcher)
        repository = FakeJournalRepository()
        viewModel = JournalViewModel(repository)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun journalsIsEmptyInitially() {
        assertTrue(viewModel.journals.value.isEmpty())
    }

    @Test
    fun addJournalAppendsWithExplicitFields() = runTest {
        val day = LocalDate.of(2024, 1, 15)
        val title = "Trip"
        val body = "Details"
        val prompt = "What happened?"

        viewModel.addJournal(day = day, title = title, body = body, prompt = prompt)
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals(1, viewModel.journals.value.size)
        val journal = viewModel.journals.value[0]
        assertEquals(day, journal.day)
        assertEquals(title, journal.title)
        assertEquals(body, journal.body)
        assertEquals(prompt, journal.prompt)
    }

    @Test
    fun addJournalReturnsSameInstanceAppended() = runTest {
        val returned = viewModel.addJournal(day = LocalDate.of(2024, 1, 16), title = "Same")
        dispatcher.scheduler.advanceUntilIdle()

        val journals = viewModel.journals.value
        assertSame(returned, journals[0])
    }

    @Test
    fun addJournalWithoutArgumentsUsesDefaults() = runTest {
        val expectedDay = LocalDate.now()
        viewModel.addJournal()
        dispatcher.scheduler.advanceUntilIdle()

        val journal = viewModel.journals.value[0]
        assertEquals(expectedDay, journal.day)
        assertEquals("", journal.title)
        assertEquals("", journal.body)
        assertEquals(null, journal.prompt)
    }

    @Test
    fun addJournalAccumulatesInCallOrder() = runTest {
        viewModel.addJournal(day = LocalDate.of(2024, 1, 1), title = "First")
        viewModel.addJournal(day = LocalDate.of(2024, 1, 2), title = "Second")
        dispatcher.scheduler.advanceUntilIdle()

        val journals = viewModel.journals.value
        assertEquals(2, journals.size)
        assertEquals("First", journals[0].title)
        assertEquals("Second", journals[1].title)
    }
}
