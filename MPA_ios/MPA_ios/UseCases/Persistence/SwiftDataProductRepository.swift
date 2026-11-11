//
//  SwiftDataProductRepository.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/11/26.
//

import Foundation
import SwiftData

/// `ProductRepository` backed by SwiftData.
///
/// `fetch(id:)`, `save(_:)`, `delete(_:)` and `reload()` come from `PersistenceRepositoryUseCase`;
/// writes go to `mainContext` and then refresh `items`.
/// `Product.id` is `@Attribute(.unique)`, so saving a new instance with an existing id replaces it.
@MainActor
@Observable
final class SwiftDataProductRepository: ProductRepository, PersistenceRepositoryUseCase {
    typealias DTO = Product

    var items: [Product] = []
    var products: [Product] { items }

    @ObservationIgnored let sortBy = [SortDescriptor(\Product.createdDate, order: .reverse)]
    /// 앱 루트에서 주입받은 메인 컨텍스트
    @ObservationIgnored let mainContext: ModelContext

    init(context: ModelContext) {
        self.mainContext = context
        reload()
    }
}
