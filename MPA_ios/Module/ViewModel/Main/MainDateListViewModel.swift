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
    @Published var showError: MainDateLocalError = .none
    
    init() {
        modelContext = Persistence.CacheContainer.mainContext
        fetchItems()
    }
    
    @discardableResult
    func addItem() -> Product {
        let newItem = Product(id: items.count + 1)
        modelContext.insert(newItem)
        
        fetchItems()
        
        return newItem
    }
    
    func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(items[index])
        }
        fetchItems()
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
    
    func tappedToolbarAddItem() -> Product {
        let id = items.max(by: { $0.id < $1.id })?.id
        
        if let id {
            return Product(id: id + 1)
        } else {
            return Product(id: 0)
        }
    }
    
    enum MainDateLocalError {
        case none
        case dataNotFound
        case swiftDataFailed(Error)
    }
}
