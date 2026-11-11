//
//  PersistenceRepositoryUseCase.swift
//  MPA_ios
//
//  Created by 백상휘 on 11/11/26.
//

import Foundation
import SwiftData

/// Shared SwiftData helpers for repository classes.
/// Conformers are classes, so the helpers update `items` without `mutating`.
@MainActor
protocol PersistenceRepositoryUseCase<DTO>: AnyObject {
    associatedtype DTO: PersistentModel & Observable where DTO.ID : Codable & Sendable
    var mainContext: ModelContext { get }
    var items: [DTO] { get set }
    var sortBy: [SortDescriptor<DTO>] { get }
}

extension PersistenceRepositoryUseCase  {
    func reload() {
        items = (try? mainContext.fetch(FetchDescriptor<DTO>(sortBy: sortBy))) ?? []
    }

    /// Inserts `dto` (a no-op if the context already holds it) and saves.
    @MainActor func save(_ dto: DTO) throws {
        mainContext.insert(dto)
#if DEBUG
        do { try mainContext.save() } catch {
            fatalError(error.localizedDescription)
        }
#else
        try? mainContext.save()
#endif
        reload()
    }
    
    @MainActor func update(_ dto: DTO) throws {
        let id = dto.id
        try mainContext.delete(model: DTO.self, where: #Predicate<DTO> {
            $0.id == id
        })
        mainContext.insert(dto)
#if DEBUG
        do { try mainContext.save() } catch {
            fatalError(error.localizedDescription)
        }
#else
        try mainContext.save()
#endif
    }
    
    @MainActor func delete(_ dto: DTO) throws {
        mainContext.delete(dto)
#if DEBUG
        do { try mainContext.save() } catch {
            fatalError(error.localizedDescription)
        }
#else
        try mainContext.save()
#endif
        reload()
    }
    
    @MainActor func fetch(id: DTO.ID) throws -> DTO? {
        let descriptor = FetchDescriptor<DTO>(predicate: #Predicate { $0.id == id })
        let result: [DTO]
#if DEBUG
        do { result = try mainContext.fetch(descriptor) } catch {
            fatalError(error.localizedDescription)
        }
#else
        result = (try? mainContext.fetch(descriptor)) ?? []
#endif
        return result.first
    }
    
    @MainActor func fetchAll() throws -> [DTO] {
        let descriptor = FetchDescriptor<DTO>.init(sortBy: [])
        let result: [DTO]
#if DEBUG
        do { result = try mainContext.fetch(descriptor) } catch {
            fatalError(error.localizedDescription)
        }
#else
        result = (try? mainContext.fetch(descriptor)) ?? []
#endif
        return result
    }
    
    @MainActor func saveOrUpdate(_ dto: DTO) throws {
        let _isExist: Bool
#if DEBUG
        do {
            _isExist = try isExist(dto)
            _isExist ? try update(dto) : try save(dto)
        } catch {
            fatalError(error.localizedDescription)
        }
#else
        _isExist = (try? isExist(dto)) ?? false
        _isExist ? try? update(dto) : try? save(dto)
#endif
        reload()
    }
    
    @MainActor func isExist(_ dto: DTO) throws -> Bool {
        let result: DTO?
#if DEBUG
        do { result = try fetch(id: dto.id) } catch {
            fatalError(error.localizedDescription)
        }
#else
        result = try? fetch(id: dto.id)
#endif
        return result != nil
    }
}
