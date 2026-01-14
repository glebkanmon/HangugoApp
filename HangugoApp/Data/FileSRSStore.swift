import Foundation

final class FileSRSStore: SRSStore {

    private let fileName = "srs_items.json"

    func load() throws -> [SRSItem] {
        let url = try fileURL()
        guard FileManager.default.fileExists(atPath: url.path) else {
            return [] // первый запуск — ничего нет
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([SRSItem].self, from: data)
    }

    func save(_ items: [SRSItem]) throws {
        let url = try fileURL()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(items)
        try data.write(to: url, options: [.atomic])
    }

    private func fileURL() throws -> URL {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "FileSRSStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Documents directory not found"])
        }
        return docs.appendingPathComponent(fileName)
    }
}
