//
//  UseCases.swift
//  MyLocalMarketiOS
//
//  Created by 백상휘 on 5/27/25.
//

import Foundation
import SwiftUICore

protocol UseCases where Repo: RepositoryProtocol, Net: NetworkProtocol {
    associatedtype Repo
    associatedtype Net
    
    var repository: Repo { get }
    var network: Net { get }
}
