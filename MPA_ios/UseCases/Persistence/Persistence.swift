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
    
    private var persistence: Persistence
    
    @MainActor
    private var mainContext: ModelContext {
        persistence.container.mainContext
    }
    
    required init(persistence: Persistence) {
        self.persistence = persistence
    }
    
    @MainActor func save(_ product: Product) throws {
        mainContext.insert(product)
#if DEBUG
        do { try mainContext.save() } catch {
            fatalError(error.localizedDescription)
        }
#else
        try? mainContext.save()
#endif
    }
    
    @MainActor func update(_ product: Product) throws {
#if DEBUG
        do { try mainContext.save() } catch {
            fatalError(error.localizedDescription)
        }
#else
        try mainContext.save()
#endif
    }
    
    @MainActor func delete(_ product: Product) throws {
        mainContext.delete(product)
#if DEBUG
        do { try mainContext.save() } catch {
            fatalError(error.localizedDescription)
        }
#else
        try mainContext.save()
#endif
    }
    
    @MainActor func fetch(id: Int) throws -> Product? {
        let descriptor = FetchDescriptor<Product>(
            predicate: #Predicate { $0.id == id },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)])
        let result: [Product]
#if DEBUG
        do { result = try mainContext.fetch(descriptor) } catch {
            fatalError(error.localizedDescription)
        }
#else
        result = (try? mainContext.fetch(descriptor)) ?? []
#endif
        return result.first
    }
    
    @MainActor func fetchAll() throws -> [Product] {
        let descriptor = FetchDescriptor<Product>.init(sortBy: [])
        let result: [Product]
#if DEBUG
        do { result = try mainContext.fetch(descriptor) } catch {
            fatalError(error.localizedDescription)
        }
#else
        result = (try? mainContext.fetch(descriptor)) ?? []
#endif
        return result
    }
    
    @MainActor func saveOrUpdate(_ product: Product) throws {
        let _isExist: Bool
#if DEBUG
        do {
            _isExist = try isExist(product)
            _isExist ? try save(product) : try update(product)
        } catch {
            fatalError(error.localizedDescription)
        }
#else
        _isExist = (try? isExist(product)) ?? false
        _isExist ? try? save(product) : try? update(product)
#endif
    }
    
    @MainActor func isExist(_ product: Product) throws -> Bool {
        let result: Product?
#if DEBUG
        do { result = try fetch(id: product.id) } catch {
            fatalError(error.localizedDescription)
        }
#else
        result = try? fetch(id: product.id)
#endif
        return result != nil
    }
}
