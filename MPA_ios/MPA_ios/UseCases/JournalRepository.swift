//
//  JournalRepository.swift
//  MPA_ios
//

import Foundation

/// Where journals are stored. The view models only know this protocol, not SwiftData.
///
/// Implementations are `@Observable`, so a view that reads `journals` (directly or
/// through a view model) is redrawn when the list changes.
@MainActor
protocol JournalRepository: AnyObject {
    /// Every stored journal, newest first.
    var journals: [Journal] { get }

    /// Adds `journal`, or saves the changes made to it if it is already stored.
    func save(_ journal: Journal) throws

    func delete(_ journal: Journal) throws
}
