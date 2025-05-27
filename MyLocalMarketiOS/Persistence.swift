//
//  Persistence.swift
//  MyLocalMarketiOS
//
//  Created by 백상휘 on 5/27/25.
//

import Foundation
import SwiftData

class Persistence {
    static var CacheContainer: ModelContainer = {
        let schema = Schema([
            Product.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
