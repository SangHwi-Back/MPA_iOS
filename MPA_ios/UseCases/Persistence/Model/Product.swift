//
//  Product.swift
//  MyLocalMarketiOS
//
//  Created by 백상휘 on 5/27/25.
//

import SwiftData
import Foundation

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

extension Product {
    var date: Date? {
        ISO8601DateFormatter.common.date(from: updatedAt ?? createdAt)
    }
}
