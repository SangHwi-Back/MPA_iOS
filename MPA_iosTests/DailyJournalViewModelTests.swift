//
//  DailyJournalViewModelTests.swift
//  MPA_iosTests
//
//  Created by Assistant
//

import Foundation
import Testing
import SwiftData
@testable import MPA_ios

@Suite("DailyJournal ViewModel Tests", .serialized)
@MainActor
struct DailyJournalViewModelTests {
    let modelContainer: ModelContainer
    let modelContext: ModelContext

    init() throws {
        // Create an in-memory model container for testing
        let schema = Schema([Product.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        modelContainer = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
        modelContext = modelContainer.mainContext

        // Override the persistence container with test container
        Persistence.CacheContainer = modelContainer
    }
    
    // MARK: - Initialization Tests

    @Test("Initialize with new product")
    func initWithNewProduct() throws {
        // Given: A new product ID that doesn't exist
        let newProductId = 999

        // When: Creating a ViewModel with the new ID
        let viewModel = DailyJournalViewModel(productId: newProductId)

        // Then: It should be in insert mode (not edit mode)
        #expect(!viewModel.isEditMode, "ViewModel should not be in edit mode for new product")
        #expect(viewModel.product.id == newProductId, "Product ID should match")
        #expect(viewModel.product.name.isEmpty, "New product name should be empty")
        #expect(viewModel.product.desc.isEmpty, "New product description should be empty")
    }
    
    @Test("Initialize with existing product")
    func initWithExistingProduct() throws {
        // Given: An existing product in the database
        let existingProduct = Product(
            id: 1,
            name: "Test Product",
            desc: "Test Description",
            price: 100,
            stock: 10,
            images: [],
            createdAt: ISO8601DateFormatter.common.string(from: Date()),
            updatedAt: nil
        )
        modelContext.insert(existingProduct)
        try modelContext.save()

        // When: Creating a ViewModel with the existing product ID
        let viewModel = DailyJournalViewModel(productId: 1)

        // Then: It should be in edit mode
        print(viewModel.product)
        #expect(viewModel.isEditMode, "ViewModel should be in edit mode for existing product")
        #expect(viewModel.product.id == 1, "Product ID should match")
        #expect(viewModel.product.name == "Test Product", "Product name should match")
        #expect(viewModel.product.desc == "Test Description", "Product description should match")
    }
    
    // MARK: - Validation Tests

    @Test("Validation with different field combinations", arguments: [
        ("", "", false, "empty fields"),
        ("Valid Name", "", false, "empty description"),
        ("", "Valid description", false, "empty name"),
        ("Valid Name", "Valid description", true, "valid fields")
    ])
    func validation(name: String, description: String, expectedEnabled: Bool, scenario: String) throws {
        // Given: A ViewModel with specific field values
        let viewModel = DailyJournalViewModel(productId: 100)
        viewModel.product.name = name
        viewModel.product.desc = description

        // Then: insertOrUpdateEnabled should match expected value
        #expect(viewModel.insertOrUpdateEnabled == expectedEnabled, "Button state incorrect for \(scenario)")
    }
    
    // MARK: - Save Tests

    @Test("Save new item")
    func saveNewItem() throws {
        // Given: A new product with valid data
        let viewModel = DailyJournalViewModel(productId: 200)
        viewModel.product.name = "New Journal Entry"
        viewModel.product.desc = "This is a new journal entry"

        // When: Saving the item
        viewModel.saveItem()

        // Then: The product should be inserted into the database
        let descriptor = FetchDescriptor<Product>(
            predicate: #Predicate { $0.id == 200 }
        )
        let results = try modelContext.fetch(descriptor)

        #expect(results.count == 1, "Should have one product in database")
        #expect(results.first?.name == "New Journal Entry", "Product name should match")
        #expect(results.first?.desc == "This is a new journal entry", "Product description should match")
    }
    
    @Test("Save existing item")
    func saveExistingItem() throws {
        // Given: An existing product in the database
        let existingProduct = Product(
            id: 300,
            name: "Original Name",
            desc: "Original Description",
            price: 100,
            stock: 10,
            images: [],
            createdAt: ISO8601DateFormatter.common.string(from: Date()),
            updatedAt: nil
        )
        modelContext.insert(existingProduct)
        try modelContext.save()

        // When: Editing and saving the product
        let viewModel = DailyJournalViewModel(productId: 300)
        viewModel.product.name = "Updated Name"
        viewModel.product.desc = "Updated Description"
        viewModel.saveItem()

        // Then: The product should be updated in the database
        let descriptor = FetchDescriptor<Product>(
            predicate: #Predicate { $0.id == 300 }
        )
        let results = try modelContext.fetch(descriptor)

        #expect(results.count == 1, "Should still have only one product")
        #expect(results.first?.name == "Updated Name", "Product name should be updated")
        #expect(results.first?.desc == "Updated Description", "Product description should be updated")
    }
    
    @Test("Save does not create duplicates")
    func saveDoesNotCreateDuplicates() throws {
        // Given: An existing product
        let existingProduct = Product(
            id: 400,
            name: "Original",
            desc: "Original",
            price: 100,
            stock: 10,
            images: [],
            createdAt: ISO8601DateFormatter.common.string(from: Date()),
            updatedAt: nil
        )
        modelContext.insert(existingProduct)
        try modelContext.save()

        // When: Editing and saving multiple times
        let viewModel = DailyJournalViewModel(productId: 400)
        viewModel.product.name = "Edit 1"
        viewModel.saveItem()

        viewModel.product.name = "Edit 2"
        viewModel.saveItem()

        // Then: Should still have only one product
        let descriptor = FetchDescriptor<Product>(
            predicate: #Predicate { $0.id == 400 }
        )
        let results = try modelContext.fetch(descriptor)

        #expect(results.count == 1, "Should not create duplicate products")
        #expect(results.first?.name == "Edit 2", "Should have the latest edit")
    }
}
