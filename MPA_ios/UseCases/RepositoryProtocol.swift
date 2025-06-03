//
//  RepositoryProtocol.swift
//  MPA_ios
//
//  Created by 백상휘 on 5/27/25.
//

import Foundation
import SwiftData

protocol RepositoryProtocol { // Must Implement
    var context: ModelContext { get }
    func fetch<T: PersistentModel>(where predicate: NSPredicate) async throws -> [T]
}
enum RepositoryTransactionTask {
    case insert(any PersistentModel),
         update(any PersistentModel),
         delete(any PersistentModel)
}
extension RepositoryProtocol {
    func fetch<T: PersistentModel>(where predicate: FetchDescriptor<T>) async throws -> [T] {
        try context.fetch(predicate)
    }
    func insert<T: PersistentModel>(data: T) -> T? {
        context.insert(data)
        return nil
    }
    func delete<T: PersistentModel>(data: T) -> T? {
        context.delete(data)
        return nil
    }
    func update<T: PersistentModel>(data: T) -> T? {
        context.insert(data)
        return nil
    }
    func inTransaction(tasks: [RepositoryTransactionTask]) {
        do {
            try context.transaction {
                for task in tasks {
                    switch task {
                    case .insert(let data):
                        self.context.insert(data)
                    case .update(let data):
                        self.context.insert(data)
                    case .delete(let data):
                        self.context.delete(data)
                    }
                }
            }
            
            try context.save()
        } catch {
            context.rollback()
        }
    }
}
