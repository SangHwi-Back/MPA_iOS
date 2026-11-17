//
//  [NO AC] Spec: specs/settings/SCREEN_SPEC.md
//
//  JournalExport.swift
//  MPA_ios
//

import Foundation

/// "기록 내보내기" file formats. Photos are never included.
enum JournalExportFormat: CaseIterable {
    case markdown
    case json

    var fileExtension: String {
        switch self {
        case .markdown: return "md"
        case .json: return "json"
        }
    }
}

/// Builds the export file: date, title, body and keywords of each entry, oldest first.
enum JournalExporter {

    static func content(_ journals: [Journal], format: JournalExportFormat) -> String {
        let sorted = journals.sorted { $0.day < $1.day }
        switch format {
        case .markdown: return markdown(sorted)
        case .json: return json(sorted)
        }
    }

    /// Writes the export to a temporary file and returns its URL.
    static func write(_ journals: [Journal], format: JournalExportFormat, now: Date = .now) throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let name = "MPA-journals-\(formatter.string(from: now)).\(format.fileExtension)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try content(journals, format: format).write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func dayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func markdown(_ journals: [Journal]) -> String {
        journals.map { journal in
            var lines = ["## \(dayString(journal.day))"]
            if !journal.title.isEmpty { lines.append("### \(journal.title)") }
            lines.append("")
            lines.append(journal.body)
            let keywords = journal.visibleKeywords.map(\.name)
            if !keywords.isEmpty {
                lines.append("")
                lines.append("키워드: " + keywords.map { "#\($0)" }.joined(separator: " "))
            }
            return lines.joined(separator: "\n")
        }
        .joined(separator: "\n\n---\n\n")
    }

    private struct Entry: Encodable {
        let date: String
        let title: String
        let body: String
        let keywords: [String]
    }

    private static func json(_ journals: [Journal]) -> String {
        let entries = journals.map {
            Entry(date: dayString($0.day), title: $0.title, body: $0.body, keywords: $0.visibleKeywords.map(\.name))
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(entries) else { return "[]" }
        return String(decoding: data, as: UTF8.self)
    }
}
