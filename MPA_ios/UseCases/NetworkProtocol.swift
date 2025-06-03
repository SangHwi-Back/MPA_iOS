//
//  NetworkProtocol.swift
//  MPA_ios
//
//  Created by 백상휘 on 5/27/25.
//

import Foundation

enum NetworkError: Error {
    case notFound, internalServerError, params([String: String])
}
protocol NetworkProtocol {}
extension NetworkProtocol {
    func post<T: Codable & Sendable>(_ url: URL, body: T) throws -> Task<T, any Error> {
        let data = try JSONEncoder().encode(body)
        return Task {
            return try await withCheckedThrowingContinuation { continuation in
                // Handle the response
                let request = URLRequest(url: url)
                let task = URLSession.shared.uploadTask(with: request, from: data) { data, response, error in
                    if error != nil {
                        continuation.resume(throwing: NetworkError.internalServerError)
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.resume(throwing: NetworkError.internalServerError)
                        return
                    }
                    
                    switch httpResponse.statusCode {
                    case 200...299:
                        if let data = data {
                            do {
                                let decoded = try JSONDecoder().decode(T.self, from: data)
                                continuation.resume(returning: decoded)
                            } catch {
                                continuation.resume(throwing: NetworkError.internalServerError)
                            }
                        } else {
                            continuation.resume(throwing: NetworkError.internalServerError)
                        }
                    case 404:
                        continuation.resume(throwing: NetworkError.notFound)
                    default:
                        continuation.resume(throwing: NetworkError.internalServerError)
                    }
                }
                
                task.resume()
            }
        }
    }
    
    func get<T: Codable>(_ url: URL) throws -> Task<T, any Error> {
        return Task {
            return try await withCheckedThrowingContinuation { continuation in
                let task = URLSession.shared.dataTask(with: url) { data, response, error in
                    if error != nil {
                        continuation.resume(throwing: NetworkError.internalServerError)
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.resume(throwing: NetworkError.internalServerError)
                        return
                    }
                    
                    switch httpResponse.statusCode {
                    case 200...299:
                        if let data = data {
                            do {
                                let decoded = try JSONDecoder().decode(T.self, from: data)
                                continuation.resume(returning: decoded)
                            } catch {
                                continuation.resume(throwing: NetworkError.internalServerError)
                            }
                        } else {
                            continuation.resume(throwing: NetworkError.internalServerError)
                        }
                    case 404:
                        continuation.resume(throwing: NetworkError.notFound)
                    default:
                        continuation.resume(throwing: NetworkError.internalServerError)
                    }
                }
                task.resume()
            }
        }
    }
}
