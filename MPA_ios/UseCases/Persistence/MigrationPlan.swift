//
//  MigrationPlan.swift
//  MPA_ios
//
//  Created by 백상휘 on 8/3/25.
//

import Foundation
import SwiftData

enum MyMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [ProductSchemaV1.self, ProductSchemaV2.self]
    }
    
    static var stages: [MigrationStage] {
        [
            MigrationStage.custom(
                fromVersion: ProductSchemaV1.self,
                toVersion: ProductSchemaV2.self,
                willMigrate: { try? $0.delete(model: Product.self) },
                didMigrate: nil)
        ]
    }
}

// V1: 기존 모델
enum ProductSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version.init(0, 0, 1)
    static var models: [any PersistentModel.Type] { [Product.self] }
    
    @Model
    final class Product {
        @Attribute(.unique)
        var id: Int
        
        var name: String
        var desc: String
        var price: UInt
        var stock: UInt
        
        var images: [String]
        var createdAt: String
        var updatedAt: String?
        
        init(
            id: Int,
            name: String,
            desc: String,
            price: UInt,
            stock: UInt,
            images: [String],
            createdAt: String,
            updatedAt: String?
        ) {
            self.id = id
            self.name = name
            self.desc = desc
            self.price = price
            self.stock = stock
            self.images = images
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }
}

// V2: 새 프로퍼티 추가
enum ProductSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version.init(0, 0, 2)
    static var models: [any PersistentModel.Type] { [Product.self] }
    
    @Model
    final class Product {
        @Attribute(.unique)
        var id: Int
        
        var name: String
        var desc: String
        var price: UInt
        var stock: UInt
        
        var images: [String]
        var createdAt: String
        var createdDate: Date
        var updatedAt: String?
        var updatedDate: Date?
        
        init(
            id: Int,
            name: String,
            desc: String,
            price: UInt,
            stock: UInt,
            images: [String],
            createdAt: String,
            updatedAt: String?
        ) {
            self.id = id
            self.name = name
            self.desc = desc
            self.price = price
            self.stock = stock
            self.images = images
            
            self.createdAt = createdAt
            self.createdDate = ISO8601DateFormatter.common.date(from: createdAt) ?? Date()
            
            self.updatedAt = updatedAt
            self.updatedDate = nil
            
            if let updatedAt, let date = ISO8601DateFormatter.common.date(from: updatedAt) {
                self.updatedDate = Date()
            }
        }
    }
}
