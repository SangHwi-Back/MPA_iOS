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
    private var modelContext: ModelContext
    private(set) var isEditMode: Bool = false
    
    @Environment(\.journalPaths) private var journalPaths
    @Binding var product: Product
    
    init(productId: Int) {
        modelContext = Persistence.CacheContainer.mainContext
        
        var descriptor = FetchDescriptor<Product>(
            predicate: #Predicate { $0.id == productId },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)])
        
        descriptor.fetchLimit = 1
        
        do {
            let result = try modelContext.fetch(descriptor)
            
            if let item = result.first {
                self._product = .constant(item)
                isEditMode = true
            }
            else {
                self._product = .constant(Product(id: result.count + 1))
                isEditMode = false
            }
        } catch {
            fatalError("Error message: \(error)")
        }
    }
    
    func saveItem() {
        modelContext.insert(product)
        try? modelContext.save()
    }
    
    private func fetchItem() {
        
    }
}
