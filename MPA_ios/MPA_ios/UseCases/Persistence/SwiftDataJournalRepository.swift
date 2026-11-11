//
//  SwiftDataJournalRepository.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/11/26.
//

import Foundation
import SwiftData

/// `JournalRepository` backed by SwiftData.
///
/// `save(_:)`, `delete(_:)` and `reload()` come from `PersistenceRepositoryUseCase`;
/// they write to `mainContext` and then refresh `items`.
@MainActor
@Observable
final class SwiftDataJournalRepository: JournalRepository, PersistenceRepositoryUseCase {
    typealias DTO = Journal

    var items: [Journal] = []
    var journals: [Journal] { items }

    @ObservationIgnored let sortBy = [SortDescriptor(\Journal.createdAt, order: .reverse)]
    /// 앱 루트에서 주입받은 메인 컨텍스트
    @ObservationIgnored let mainContext: ModelContext

    init(context: ModelContext) {
        self.mainContext = context
        reload()
    }
}
