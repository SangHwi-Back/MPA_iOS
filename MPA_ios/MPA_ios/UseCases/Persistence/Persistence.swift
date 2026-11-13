//
//  Persistence.swift
//  MPA_ios
//
//  Created by 백상휘 on 5/27/25.
//

import Foundation
import SwiftData

class Persistence {
    
    static let shared: Persistence = Persistence()
    
    let container: ModelContainer
    
    init() {
        let schema = Schema([
            Journal.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            self.container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
