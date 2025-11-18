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
    @Published private(set) var items: [Product] = []
    @Published var showError: MainDateLocalError = .none
    
    private var repository: ProductRepositoryProtocol
    
    init(repository: ProductRepositoryProtocol) {
        self.repository = repository
        fetchItems()
    }
    
    @discardableResult
    func addItem() -> Product {
        let newItem = Product(id: items.count + 1)
        
        try? repository.save(newItem)
        return newItem
    }
    
    func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            try? repository.delete(items[index])
        }
        fetchItems()
    }
    
    func fetchItems() {
        items = (try? repository.fetchAll()) ?? []
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
