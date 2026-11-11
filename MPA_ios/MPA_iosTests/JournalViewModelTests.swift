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
}
