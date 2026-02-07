//
//  ProductRepositoryProtocol.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/18/25.
//

import Foundation

@MainActor
protocol ProductRepositoryProtocol {
    init(persistence: Persistence)
    func save(_ product: Product) throws
    func update(_ product: Product) throws
    func delete(_ product: Product) throws
    func saveOrUpdate(_ product: Product) throws
    func isExist(_ product: Product) throws -> Bool
    func fetch(id: Int) throws -> Product?
    func fetchAll() throws -> [Product]
}
