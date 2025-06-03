//
//  ProductViewModel.swift
//  MPA_ios
//
//  Created by 백상휘 on 5/27/25.
//

import Foundation
import SwiftData
import SwiftUICore

class ProductViewModel: ObservableObject {
    let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    static var shared: ProductViewModel {
        .init(context: .init(Persistence.CacheContainer))
    }
}

extension ProductViewModel: EnvironmentKey {
    static let defaultValue = ProductViewModel(context: .init(Persistence.CacheContainer))
}

extension EnvironmentValues {
    var productViewModel: ProductViewModel {
        get {
            self[ProductViewModel.self]
        } set {
            self[ProductViewModel.self] = newValue
        }
    }
}
