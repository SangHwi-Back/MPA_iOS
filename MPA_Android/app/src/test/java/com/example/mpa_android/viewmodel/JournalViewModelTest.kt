@file:OptIn(ExperimentalTime::class, ExperimentalCoroutinesApi::class)

package com.example.mpa_android.viewmodel

import com.android.identity.util.UUID
import com.example.mpa_android.data.JournalRepository
import com.example.mpa_android.model.Journal
import java.time.LocalDate
import kotlin.time.Clock
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
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

private class FakeJournalRepository : JournalRepository {
    val state = MutableStateFlow<List<Journal>>(emptyList())
    override val journals: Flow<List<Journal>> = state

    /** Upserts by id, like the Room repository. */
    override suspend fun save(journal: Journal) {
        state.value = if (state.value.any { it.id == journal.id }) {
            state.value.map { if (it.id == journal.id) journal else it }
        } else {
            state.value + journal
        }
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

    @Test
    fun deleteJournalHidesEntryButKeepsItInRepository() = runTest {
        val journal = viewModel.addJournal(day = LocalDate.of(2024, 1, 1), title = "First")
        dispatcher.scheduler.advanceUntilIdle()

        viewModel.deleteJournal(journal)
        dispatcher.scheduler.advanceUntilIdle()

        assertTrue(viewModel.visibleJournals.value.isEmpty())
        assertEquals(1, viewModel.journals.value.size)
        assertEquals(journal.id, viewModel.pendingDeletion.value?.id)
    }

    @Test
    fun undoDeletionRestoresEntry() = runTest {
        val journal = viewModel.addJournal(day = LocalDate.of(2024, 1, 1), title = "First")
        dispatcher.scheduler.advanceUntilIdle()
        viewModel.deleteJournal(journal)
        dispatcher.scheduler.advanceUntilIdle()

        viewModel.undoDeletion()
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals(1, viewModel.visibleJournals.value.size)
        assertEquals(null, viewModel.pendingDeletion.value)
        assertEquals(1, repository.state.value.size)
    }

    @Test
    fun commitDeletionRemovesEntryFromRepository() = runTest {
        val journal = viewModel.addJournal(day = LocalDate.of(2024, 1, 1), title = "First")
        dispatcher.scheduler.advanceUntilIdle()
        viewModel.deleteJournal(journal)
        dispatcher.scheduler.advanceUntilIdle()

        viewModel.commitDeletion()
        dispatcher.scheduler.advanceUntilIdle()

        assertTrue(repository.state.value.isEmpty())
        assertTrue(viewModel.visibleJournals.value.isEmpty())
        assertEquals(null, viewModel.pendingDeletion.value)
    }

    @Test
    fun secondDeletionCommitsFirstAndKeepsOnlyLatestPending() = runTest {
        val first = viewModel.addJournal(day = LocalDate.of(2024, 1, 1), title = "First")
        val second = viewModel.addJournal(day = LocalDate.of(2024, 1, 2), title = "Second")
        dispatcher.scheduler.advanceUntilIdle()

        viewModel.deleteJournal(first)
        dispatcher.scheduler.advanceUntilIdle()
        viewModel.deleteJournal(second)
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals(listOf(second.id), repository.state.value.map { it.id })
        assertEquals(second.id, viewModel.pendingDeletion.value?.id)

        viewModel.undoDeletion()
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals(listOf(second.id), viewModel.visibleJournals.value.map { it.id })
    }

    // region Query

    @Test
    fun journalReturnsNullWhenNoJournalExistsForTheDay() = runTest {
        assertNull(viewModel.journal(on = LocalDate.of(2024, 1, 15)))
    }

    @Test
    fun journalReturnsTheJournalForTheGivenDay() = runTest {
        val day = LocalDate.of(2024, 1, 15)
        val journal = Journal(day = day, createdAt = Clock.System.now(), title = "Trip", body = "Details")
        repository.state.value = listOf(journal)
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals(journal.id, viewModel.journal(on = day)?.id)
    }

    @Test
    fun journalReturnsTheCorrectJournalAmongMultiple() = runTest {
        val day1 = LocalDate.of(2024, 1, 15)
        val day2 = LocalDate.of(2024, 2, 20)
        val journal1 = Journal(day = day1, createdAt = Clock.System.now(), title = "One")
        val journal2 = Journal(day = day2, createdAt = Clock.System.now(), title = "Two")
        repository.state.value = listOf(journal1, journal2)
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals(journal1.id, viewModel.journal(on = day1)?.id)
        assertEquals(journal2.id, viewModel.journal(on = day2)?.id)
    }

    // endregion

    // region Saving

    @Test
    fun saveStoresANewJournal() = runTest {
        val journal = Journal(day = LocalDate.of(2024, 1, 15), createdAt = Clock.System.now(), title = "Trip", body = "Details")

        viewModel.save(journal)
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals(1, repository.state.value.size)
        assertTrue(repository.state.value.any { it.id == journal.id })
    }

    @Test
    fun saveUpdatesAnExistingJournal() = runTest {
        val journal = Journal(day = LocalDate.of(2024, 1, 15), createdAt = Clock.System.now(), title = "Trip", body = "Details")
        repository.state.value = listOf(journal)
        dispatcher.scheduler.advanceUntilIdle()

        viewModel.save(journal.copy(title = "Updated", body = "New details"))
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals(1, repository.state.value.size)
        assertEquals("Updated", viewModel.journals.value.first().title)
        assertEquals("New details", viewModel.journals.value.first().body)
    }

    @Test
    fun addJournalUpdatesExistingJournalForSameDay() = runTest {
        val day = LocalDate.of(2024, 1, 15)

        val first = viewModel.addJournal(day = day, title = "Trip", body = "Details")
        dispatcher.scheduler.advanceUntilIdle()
        val second = viewModel.addJournal(day = day, title = "Trip Updated", body = "More details")
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals(1, repository.state.value.size)
        assertEquals(first.id, second.id)
        assertEquals("Trip Updated", second.title)
        assertEquals("More details", second.body)
    }

    // endregion
}
