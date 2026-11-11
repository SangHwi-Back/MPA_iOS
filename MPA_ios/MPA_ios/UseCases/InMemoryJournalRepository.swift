//
//  [NO AC]
//
//  InMemoryJournalRepository.swift
//  MPA_ios
//

import Foundation

/// `JournalRepository` that keeps journals in an array. For previews and tests.
@MainActor
@Observable
final class InMemoryJournalRepository: JournalRepository {
    private(set) var journals: [Journal]

    init(journals: [Journal] = []) {
        self.journals = Self.newestFirst(journals)
    }

    func save(_ journal: Journal) throws {
        if !journals.contains(where: { $0.id == journal.id }) {
            journals = Self.newestFirst(journals + [journal])
        }
    }

    func delete(_ journal: Journal) throws {
        journals.removeAll { $0.id == journal.id }
    }

    private static func newestFirst(_ journals: [Journal]) -> [Journal] {
        journals.sorted { $0.createdAt > $1.createdAt }
    }
}
