//
//  [NO AC] Spec: specs/journal/SCREEN_SPEC.md
//
//  JournalViewModelTests.swift
//  MPA_iosTests
//

import Foundation
import Testing
@testable import MPA_ios

@Suite("Journal ViewModel Tests", .serialized)
@MainActor
struct JournalViewModelTests {

    private func makeViewModel(_ journals: [Journal] = []) -> (JournalViewModel, InMemoryJournalRepository) {
        let repository = InMemoryJournalRepository(journals: journals)
        return (JournalViewModel(repository: repository), repository)
    }

    // MARK: - Adding

    @Test("Entries is empty initially")
    func entriesIsEmptyInitially() {
        let (viewModel, _) = makeViewModel()
        #expect(viewModel.entries.isEmpty)
    }

    @Test("addJournal stores explicit fields")
    func addJournalStoresExplicitFields() {
        let (viewModel, repository) = makeViewModel()
        let day = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 15))!

        viewModel.addJournal(day: day, title: "Trip", body: "Details", prompt: "What happened?")

        #expect(viewModel.entries.count == 1)
        let journal = viewModel.entries[0]
        #expect(Calendar.current.isDate(journal.day, inSameDayAs: day))
        #expect(journal.title == "Trip")
        #expect(journal.body == "Details")
        #expect(journal.prompt == "What happened?")
        #expect(repository.journals.count == 1)
    }

    @Test("addJournal returns the stored instance")
    func addJournalReturnsTheStoredInstance() {
        let (viewModel, _) = makeViewModel()

        let returned = viewModel.addJournal(title: "Same")

        #expect(returned?.id == viewModel.entries[0].id)
    }

    @Test("addJournal without arguments uses defaults")
    func addJournalWithoutArgumentsUsesDefaults() {
        let (viewModel, _) = makeViewModel()

        viewModel.addJournal()

        let journal = viewModel.entries[0]
        #expect(Calendar.current.isDate(journal.day, inSameDayAs: .now))
        #expect(journal.title == "")
        #expect(journal.body == "")
        #expect(journal.prompt == nil)
    }

    @Test("Entries are newest first")
    func entriesAreNewestFirst() {
        let old = Journal(createdAt: Date(timeIntervalSince1970: 100), title: "Old")
        let new = Journal(createdAt: Date(timeIntervalSince1970: 200), title: "New")
        let (viewModel, _) = makeViewModel([old, new])

        #expect(viewModel.entries.map(\.title) == ["New", "Old"])
    }

    // MARK: - Deleting with undo

    @Test("delete hides the entry but keeps it stored until commit")
    func deleteHidesTheEntryButKeepsItStored() {
        let journal = Journal(title: "A")
        let (viewModel, repository) = makeViewModel([journal])

        viewModel.delete(journal, autoCommit: false)

        #expect(viewModel.entries.isEmpty)
        #expect(viewModel.pendingDeletion?.journal.id == journal.id)
        #expect(repository.journals.count == 1)
    }

    @Test("undoDeletion shows the entry again")
    func undoDeletionShowsTheEntryAgain() {
        let journal = Journal(title: "A")
        let (viewModel, repository) = makeViewModel([journal])

        viewModel.delete(journal, autoCommit: false)
        viewModel.undoDeletion()

        #expect(viewModel.entries.count == 1)
        #expect(viewModel.pendingDeletion == nil)
        #expect(repository.journals.count == 1)
    }

    @Test("commitPendingDeletion removes it from the repository")
    func commitPendingDeletionRemovesIt() {
        let journal = Journal(title: "A")
        let (viewModel, repository) = makeViewModel([journal])

        viewModel.delete(journal, autoCommit: false)
        viewModel.commitPendingDeletion()

        #expect(repository.journals.isEmpty)
        #expect(viewModel.pendingDeletion == nil)
    }

    @Test("Deleting another entry commits the previous one")
    func deletingAnotherEntryCommitsThePreviousOne() {
        let a = Journal(title: "A")
        let b = Journal(title: "B")
        let (viewModel, repository) = makeViewModel([a, b])

        viewModel.delete(a, autoCommit: false)
        viewModel.delete(b, autoCommit: false)

        #expect(repository.journals.map(\.id) == [b.id])
        #expect(viewModel.pendingDeletion?.journal.id == b.id)
        #expect(viewModel.entries.isEmpty)
    }

    // MARK: - Query

    @Test("journal returns nil when no journal exists for the day")
    func journalReturnsNilWhenNoJournalExistsForTheDay() {
        let (viewModel, _) = makeViewModel()
        let day = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 15))!

        #expect(viewModel.journal(on: day) == nil)
    }

    @Test("journal returns the journal for the given day")
    func journalReturnsTheJournalForTheGivenDay() {
        let day = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 15))!
        let journal = Journal(day: day, title: "Trip", body: "Details")
        let (viewModel, _) = makeViewModel([journal])

        #expect(viewModel.journal(on: day)?.id == journal.id)
    }

    @Test("journal returns the correct journal among multiple")
    func journalReturnsTheCorrectJournalAmongMultiple() {
        let day1 = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 15))!
        let day2 = Calendar.current.date(from: DateComponents(year: 2024, month: 2, day: 20))!
        let journal1 = Journal(day: day1, title: "One")
        let journal2 = Journal(day: day2, title: "Two")
        let (viewModel, _) = makeViewModel([journal1, journal2])

        #expect(viewModel.journal(on: day1)?.id == journal1.id)
        #expect(viewModel.journal(on: day2)?.id == journal2.id)
    }

    @Test("journal compares days ignoring time")
    func journalComparesDaysIgnoringTime() {
        let dayWithTime = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 15, hour: 15, minute: 30))!
        let dayMorning = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 15, hour: 9, minute: 0))!
        let journal = Journal(day: dayWithTime, title: "Trip")
        let (viewModel, _) = makeViewModel([journal])

        #expect(viewModel.journal(on: dayMorning)?.id == journal.id)
    }

    // MARK: - Saving

    @Test("save stores a new journal")
    func saveStoresANewJournal() {
        let (viewModel, repository) = makeViewModel()
        let journal = Journal(
            day: Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 15))!,
            title: "Trip",
            body: "Details"
        )

        viewModel.save(journal)

        #expect(repository.journals.count == 1)
        #expect(repository.journals.contains { $0.id == journal.id })
    }

    @Test("save works with an existing journal reference")
    func saveWorksWithAnExistingJournalReference() {
        let journal = Journal(
            day: Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 15))!,
            title: "Trip",
            body: "Details"
        )
        let (viewModel, repository) = makeViewModel([journal])

        journal.title = "Updated"
        journal.body = "New details"
        viewModel.save(journal)

        #expect(repository.journals.count == 1)
        #expect(viewModel.entries.first?.title == "Updated")
        #expect(viewModel.entries.first?.body == "New details")
    }

    @Test("addJournal updates existing journal for same day")
    func addJournalUpdatesExistingJournalForSameDay() {
        let day = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 15))!
        let (viewModel, repository) = makeViewModel()

        let first = viewModel.addJournal(day: day, title: "Trip", body: "Details")
        let second = viewModel.addJournal(day: day, title: "Trip Updated", body: "More details")

        #expect(repository.journals.count == 1)
        #expect(second?.id == first?.id)
        #expect(second?.title == "Trip Updated")
        #expect(second?.body == "More details")
    }

    @Test("addJournal returns the same instance when updating")
    func addJournalReturnsTheSameInstanceWhenUpdating() {
        let day = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 15))!
        let (viewModel, _) = makeViewModel()

        let first = viewModel.addJournal(day: day, title: "Trip", body: "Details")
        let second = viewModel.addJournal(day: day, title: "Trip Updated", body: "More details")

        #expect(second?.id == first?.id)
        #expect(viewModel.entries.count == 1)
    }
}
