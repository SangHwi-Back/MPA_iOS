//
//  DailyJournalViewModelTests.swift
//  MPA_iosTests
//

import Foundation
import Testing
@testable import MPA_ios

@Suite("DailyJournal ViewModel Tests", .serialized)
@MainActor
struct DailyJournalViewModelTests {

    // MARK: - Initialization Tests

    @Test("Initialize with new product")
    func initWithNewProduct() throws {
        let mockRepo = MockProductRepository()
        let viewModel = DailyJournalViewModel(repository: mockRepo, productId: 999)

        #expect(!viewModel.isEditMode, "새 항목은 편집 모드가 아니어야 합니다")
        #expect(viewModel.product.id == 999, "Product ID가 일치해야 합니다")
        #expect(viewModel.product.name.isEmpty, "새 항목의 이름은 비어 있어야 합니다")
        #expect(viewModel.product.desc.isEmpty, "새 항목의 설명은 비어 있어야 합니다")
    }

    @Test("Initialize with existing product")
    func initWithExistingProduct() throws {
        let mockRepo = MockProductRepository()
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
        try mockRepo.save(existingProduct)

        let viewModel = DailyJournalViewModel(repository: mockRepo, productId: 1)

        #expect(viewModel.isEditMode, "기존 항목은 편집 모드여야 합니다")
        #expect(viewModel.product.id == 1, "Product ID가 일치해야 합니다")
        #expect(viewModel.product.name == "Test Product", "이름이 일치해야 합니다")
        #expect(viewModel.product.desc == "Test Description", "설명이 일치해야 합니다")
    }

    // MARK: - Validation Tests

    @Test("Validation with different field combinations", arguments: [
        ("", "", false, "empty fields"),
        ("Valid Name", "", false, "empty description"),
        ("", "Valid description", false, "empty name"),
        ("Valid Name", "Valid description", true, "valid fields")
    ])
    func validation(name: String, description: String, expectedEnabled: Bool, scenario: String) throws {
        let mockRepo = MockProductRepository()
        let viewModel = DailyJournalViewModel(repository: mockRepo, productId: 100)
        viewModel.product.name = name
        viewModel.product.desc = description

        #expect(viewModel.insertOrUpdateEnabled == expectedEnabled, "시나리오 '\(scenario)'에서 버튼 상태가 올바르지 않습니다")
    }

    // MARK: - Save Tests

    @Test("Save new item")
    func saveNewItem() throws {
        let mockRepo = MockProductRepository()
        let viewModel = DailyJournalViewModel(repository: mockRepo, productId: 200)
        viewModel.product.name = "New Journal Entry"
        viewModel.product.desc = "This is a new journal entry"

        viewModel.saveItem()

        let saved = try mockRepo.fetch(id: 200)
        #expect(saved != nil, "저장된 항목이 있어야 합니다")
        #expect(saved?.name == "New Journal Entry", "이름이 일치해야 합니다")
        #expect(saved?.desc == "This is a new journal entry", "설명이 일치해야 합니다")
    }

    @Test("Save existing item")
    func saveExistingItem() throws {
        let mockRepo = MockProductRepository()
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
        try mockRepo.save(existingProduct)

        let viewModel = DailyJournalViewModel(repository: mockRepo, productId: 300)
        viewModel.product.name = "Updated Name"
        viewModel.product.desc = "Updated Description"
        viewModel.saveItem()

        let updated = try mockRepo.fetch(id: 300)
        #expect(updated?.name == "Updated Name", "이름이 업데이트되어야 합니다")
        #expect(updated?.desc == "Updated Description", "설명이 업데이트되어야 합니다")
    }

    @Test("Save does not create duplicates")
    func saveDoesNotCreateDuplicates() throws {
        let mockRepo = MockProductRepository()
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
        try mockRepo.save(existingProduct)

        let viewModel = DailyJournalViewModel(repository: mockRepo, productId: 400)
        viewModel.product.name = "Edit 1"
        viewModel.saveItem()

        viewModel.product.name = "Edit 2"
        viewModel.saveItem()

        let all = mockRepo.products
        let matching = all.filter { $0.id == 400 }
        #expect(matching.count == 1, "중복 항목이 생성되어서는 안 됩니다")
        #expect(matching.first?.name == "Edit 2", "마지막 편집 내용이 저장되어야 합니다")
    }
}
