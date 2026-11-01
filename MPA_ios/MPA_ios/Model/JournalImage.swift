//
//  JournalImage.swift
//  MPA_ios
//

import Foundation

struct JournalImage: Codable, Identifiable, Equatable {
    let id: UUID
    var fileName: String
    var displayName: String

    init(id: UUID = UUID(), fileName: String = "", displayName: String = "") {
        self.id = id
        self.fileName = fileName.isEmpty ? Self.buildFileName(id: id, displayName: displayName) : fileName
        self.displayName = displayName
    }

    static func sanitizeFileName(_ name: String) -> String {
        let invalidChars = CharacterSet(charactersIn: "/\\:*?\"<>|")
        return name.unicodeScalars
            .map { invalidChars.contains($0) ? "_" : String($0) }
            .joined()
    }

    static func buildFileName(id: UUID, displayName: String) -> String {
        let shortId = String(id.uuidString.prefix(8))
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "\(shortId).jpg"
        }
        let sanitized = sanitizeFileName(trimmed)
        return "\(shortId)_\(sanitized).jpg"
    }

    func toJSONString() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func from(jsonString: String) -> JournalImage? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(JournalImage.self, from: data)
    }

    static var imagesDirectoryURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("journal_images")
    }

    var fileURL: URL {
        Self.imagesDirectoryURL.appendingPathComponent(fileName)
    }
}
