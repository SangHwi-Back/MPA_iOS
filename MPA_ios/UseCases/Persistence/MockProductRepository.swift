//
//  MockProductRepository.swift
//  MPA_ios
//
//  Created by 백상휘 on 2/7/26.
//

import Foundation
import SwiftData

@MainActor
class MockProductRepository: ProductRepositoryProtocol {
    private var products: [Product] = []

    required init(persistence: Persistence) {
        // Preview용이므로 persistence는 사용하지 않음
    }

    convenience init(withSampleData: Bool = false) {
        self.init(persistence: Persistence())
        if withSampleData {
            self.products = Self.sampleProducts
        }
    }

    func save(_ product: Product) throws {
        products.append(product)
    }

    func update(_ product: Product) throws {
        if let index = products.firstIndex(where: { $0.id == product.id }) {
            products[index] = product
        }
    }

    func delete(_ product: Product) throws {
        products.removeAll { $0.id == product.id }
    }

    func saveOrUpdate(_ product: Product) throws {
        if try isExist(product) {
            try update(product)
        } else {
            try save(product)
        }
    }

    func isExist(_ product: Product) throws -> Bool {
        products.contains { $0.id == product.id }
    }

    func fetch(id: Int) throws -> Product? {
        products.first { $0.id == id }
    }

    func fetchAll() throws -> [Product] {
        products
    }

    static var sampleProducts: [Product] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: now)!
        let fourDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: now)!
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: now)!
        let yearAgo = Calendar.current.date(byAdding: .month, value: -1, to: now)!

        return [
            Product(
                id: 1,
                name: "아침 운동", desc: "30분 조깅과 스트레칭",
                price: 0, stock: 1, images: [],
                createdAt: formatter.string(from: now), updatedAt: nil
            ),
            Product(
                id: 2,
                name: "독서", desc: "Swift 프로그래밍 책 읽기",
                price: 0, stock: 1, images: [],
                createdAt: formatter.string(from: yesterday), updatedAt: formatter.string(from: yesterday)
            ),
            Product(
                id: 3,
                name: "프로젝트 작업", desc: "MPA 앱 개발",
                price: 0, stock: 1, images: [],
                createdAt: formatter.string(from: twoDaysAgo), updatedAt: nil
            ),
            Product(
                id: 4,
                name: "운동하기", desc: "수영과 헬스",
                price: 0, stock: 1, images: [],
                createdAt: formatter.string(from: fourDaysAgo), updatedAt: nil
            ),
            Product(
                id: 5,
                name: "개인 프로젝트 기획하기", desc: "MPA 앱 개발",
                price: 0, stock: 1, images: [],
                createdAt: formatter.string(from: monthAgo), updatedAt: nil
            ),
            Product(
                id: 6,
                name: "근무", desc: "열심히 앱 개발", price: 0, stock: 1, images: [],
                createdAt: formatter.string(from: yearAgo), updatedAt: nil
            )
        ]
    }
}
