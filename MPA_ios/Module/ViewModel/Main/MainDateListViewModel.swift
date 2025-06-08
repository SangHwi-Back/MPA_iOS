//
//  DateListViewModel.swift
//  MPA_ios
//
//  Created by 백상휘 on 6/8/25.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
class MainDateListViewModel: ObservableObject {
    private var modelContext: ModelContext
    
    @Published private(set) var items: [Product] = []

    init() {
        modelContext = Persistence.CacheContainer.mainContext
        fetchItems()
    }
    
    func addItem() {
        withAnimation {
            let newItem = Product(
                id: items.count + 1,
                name: "New Item",
                desc: "",
                price: 0,
                stock: 0,
                images: [],
                createdAt: ISO8601DateFormatter.common.string(from: Date()),
                updatedAt: nil)
            modelContext.insert(newItem)
            fetchItems()
        }
    }
    
    func deleteItems(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
            fetchItems()
        }
    }
    
    func fetchItems() {
        let descriptor = FetchDescriptor<Product>(sortBy: [
            .init(\.createdAt, order: .forward)
        ])
        do {
            items = try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching items: \(error)")
        }
    }
}
