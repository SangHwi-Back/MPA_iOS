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
    
    @Binding private(set) var navigationPath: [Product]

    init(navigationPath: Binding<[Product]>) {
        _navigationPath = navigationPath
        
        modelContext = Persistence.CacheContainer.mainContext
        fetchItems()
    }
    
    @discardableResult
    func addItem() -> Product {
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
    
    func tappedList(_ id: Int) {
        do {
            let item = try modelContext.fetch(FetchDescriptor(predicate: #Predicate<Product> { $0.id == id }))
            
            if let item = item.first {
                navigationPath.append(item)
            }
            else {
                self.showError = .dataNotFound
            }
        } catch {
            self.showError = .swiftDataFailed(error)
        }
    }
    
    func tappedToolbarAddItem() {
        let newItem = addItem()
        tappedList(newItem.id)
    }
    
    enum MainDateLocalError {
        case none
        case dataNotFound
        case swiftDataFailed(Error)
    }
}
