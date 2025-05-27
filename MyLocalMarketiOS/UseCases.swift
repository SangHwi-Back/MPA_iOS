//
//  UseCases.swift
//  MyLocalMarketiOS
//
//  Created by 백상휘 on 5/27/25.
//

import Foundation
import SwiftUICore

protocol UseCases where R: RepositoryProtocol, N: NetworkProtocol {
    associatedtype R
    associatedtype N
    
    var repository: R { get }
    var network: N { get }
}

