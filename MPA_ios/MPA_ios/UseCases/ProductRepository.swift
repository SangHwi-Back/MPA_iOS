//
//  ProductRepository.swift
//  MPA_ios
//

import Foundation

/// Where products are stored. The view models only know this protocol, not SwiftData.
///
/// Implementations are `@Observable`, so a view that reads `products` (directly or
/// through a view model) is redrawn when the list changes.
@MainActor
protocol ProductRepository: AnyObject {
    /// Every stored product, newest `createdDate` first.
    var products: [Product] { get }

    func fetch(id: Int) throws -> Product?

    /// Adds `product`, or saves the changes made to it if it is already stored.
    func save(_ product: Product) throws

    func delete(_ product: Product) throws
}
