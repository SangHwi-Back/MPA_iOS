//
//  Product.swift
//  MPA_ios
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
        
        func getDate(_ dateString: String) -> Date {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let date = formatter.date(from: dateString) {
                return date
            } else {
                return Date()
            }
        }
        
        self.createdDate = getDate(createdAt)
        
        self.updatedAt = updatedAt
        if let updatedAt {
            self.updatedDate = getDate(updatedAt)
        }
        else {
            self.updatedDate = nil
        }
    }
    
    convenience init(id: Int) {
        self.init(
            id: id,
            name: "",
            desc: "",
            price: 0,
            stock: 0,
            images: [],
            createdAt: ISO8601DateFormatter.common.string(from: Date()),
            updatedAt: nil)
    }
}

extension Product {
    var date: Date? {
        ISO8601DateFormatter.common.date(from: updatedAt ?? createdAt)
    }
}
