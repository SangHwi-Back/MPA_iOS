//
//  DateListViewModel.swift
//  MPA_ios
//
//  Created by 백상휘 on 6/8/25.
//

import SwiftUI

@MainActor
@Observable
final class ProductViewModel {
    /// Stored products, newest first. Updates on its own when the repository changes.
    var items: [Product] { repository.products }
    var showError: MainDateLocalError = .none
    
    @ObservationIgnored private let repository: any ProductRepository
    
    init(repository: any ProductRepository) {
        self.repository = repository
    }
    
    @discardableResult
    func addItem() -> Product {
        let newItem = Product(id: items.count + 1)
#if DEBUG
        do { try repository.save(newItem) } catch {
            fatalError(error.localizedDescription)
        }
#else
        try? repository.save(newItem)
#endif
        return newItem
    }
    
    func deleteItems(at offsets: IndexSet) {
        // Resolve the products first: `items` shrinks after each delete.
        let products = offsets.map { items[$0] }
        for product in products {
#if DEBUG
            do { try repository.delete(product) } catch {
                fatalError(error.localizedDescription)
            }
#else
            try? repository.delete(product)
#endif
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
