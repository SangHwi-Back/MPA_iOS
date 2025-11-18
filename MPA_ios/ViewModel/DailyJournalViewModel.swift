//
//  DailyJournalViewModel.swift
//  MPA_ios
//
//  Created by 백상휘 on 8/3/25.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
class DailyJournalViewModel: ObservableObject {
    private(set) var isEditMode: Bool = false
    
    @Environment(\.journalPaths) private var journalPaths
    private var repository: ProductRepositoryProtocol
    
    private var productId: Int
    @Binding var product: Product
    
    var insertOrUpdateEnabled: Bool {
        product.name.isEmpty.not && product.desc.isEmpty.not
    }
    
    init(repository: any ProductRepositoryProtocol, productId: Int) {
        self.productId = productId
        self.repository = repository
        
        do {
            let product = try self.repository.fetch(id: productId)
            
            if let item = product {
                self._product = .constant(item)
                isEditMode = true
            }
            else {
                self._product = .constant(Product(id: productId))
                isEditMode = false
            }
        } catch {
            fatalError("Error message: \(error)")
        }
    }
    
    func saveItem() {
        guard isEditMode.not else {
            try? repository.update(product)
            return
        }
        
        try? repository.save(product)
    }
}
