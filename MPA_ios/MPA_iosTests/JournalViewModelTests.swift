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
    
    @Test("Entries is empty initially")
    func entriesIsEmptyInitially() throws {
        let viewModel = JournalViewModel()
        #expect(viewModel.entries.isEmpty)
    }
    
    @Test("addJournal appends with explicit fields")
    func addJournalAppendsWithExplicitFields() throws {
        let viewModel = JournalViewModel()
        let day = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 15))!
        let title = "Trip"
        let body = "Details"
        let prompt = "What happened?"
        
        viewModel.addJournal(day: day, title: title, body: body, prompt: prompt)
        
        #expect(viewModel.entries.count == 1)
        let journal = viewModel.entries[0]
        #expect(Calendar.current.isDate(journal.day, inSameDayAs: day))
        #expect(journal.title == title)
        #expect(journal.body == body)
        #expect(journal.prompt == prompt)
    }
    
    @Test("addJournal returns the same instance appended")
    func addJournalReturnsSameInstanceAppended() throws {
        let viewModel = JournalViewModel()
        let day = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 16))!
        
        let returned = viewModel.addJournal(day: day, title: "Same")
        
        #expect(returned.id == viewModel.entries[0].id)
    }
    
    @Test("addJournal without arguments uses defaults")
    func addJournalWithoutArgumentsUsesDefaults() throws {
        let viewModel = JournalViewModel()
        let expectedDay = Calendar.current.startOfDay(for: .now)
        
        viewModel.addJournal()
        
        let journal = viewModel.entries[0]
        #expect(Calendar.current.isDate(journal.day, inSameDayAs: expectedDay))
        #expect(journal.title == "")
        #expect(journal.body == "")
        #expect(journal.prompt == nil)
    }
    
    @Test("addJournal accumulates in call order")
    func addJournalAccumulatesInCallOrder() throws {
        let viewModel = JournalViewModel()
        let day1 = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let day2 = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 2))!
        
        viewModel.addJournal(day: day1, title: "First")
        viewModel.addJournal(day: day2, title: "Second")
        
        #expect(viewModel.entries.count == 2)
        #expect(viewModel.entries[0].title == "First")
        #expect(viewModel.entries[1].title == "Second")
    }
}
