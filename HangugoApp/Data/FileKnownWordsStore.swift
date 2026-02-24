import Foundation

final class FileKnownWordsStore: KnownWordsStore {

    private let fileName = "known_word_ids.json"

    func load() throws -> Set<String> {
        let url = try fileURL()
        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let ids = try decoder.decode([String].self, from: data)
        return Set(ids)
    }

    func save(_ ids: Set<String>) throws {
        let url = try fileURL()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(Array(ids).sorted())
        try data.write(to: url, options: [.atomic])
    }

    private func fileURL() throws -> URL {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(
                domain: "FileKnownWordsStore",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Documents directory not found"]
            )
        }
        return docs.appendingPathComponent(fileName)
    }
}
