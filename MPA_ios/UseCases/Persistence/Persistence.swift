//
//  Persistence.swift
//  MPA_ios
//
//  Created by 백상휘 on 5/27/25.
//

import Foundation
import SwiftData

class Persistence {
    let container: ModelContainer
    
    init() {
        let schema = Schema([
            Product.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            self.container = try ModelContainer(
                for: schema,
                migrationPlan: MyMigrationPlan.self,
                configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}

class ProductRepository: @MainActor ProductRepositoryProtocol {
    
    var persistence: Persistence
    @MainActor
    private var mainContext: ModelContext {
        persistence.container.mainContext
    }
    
    required init(persistence: Persistence) {
        self.persistence = persistence
    }
    @MainActor func save(_ product: Product) throws {
        mainContext.insert(product)
        try mainContext.save()
    }
    
    @MainActor func update(_ product: Product) throws {
        try mainContext.save()
    }
    
    @MainActor func delete(_ product: Product) throws {
        mainContext.delete(product)
        try mainContext.save()
    }
    
    @MainActor func fetch(id: Int) throws -> Product? {
        let descriptor = FetchDescriptor<Product>(
            predicate: #Predicate { $0.id == id },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)])
        
        let result = try mainContext.fetch(descriptor)
        
        return result.first
    }
    
    @MainActor func fetchAll() throws -> [Product] {
        let descriptor = FetchDescriptor<Product>.init(sortBy: [])
        
        let result = try mainContext.fetch(descriptor)
        
        return result
    }
    
    @MainActor func saveOrUpdate(_ product: Product) throws {
        let isExist = try isExist(product)
        
        if isExist {
            try save(product)
        } else {
            try update(product)
        }
    }
    
    @MainActor func isExist(_ product: Product) throws -> Bool {
        let result = try fetch(id: product.id)
        return result != nil
    }
}
