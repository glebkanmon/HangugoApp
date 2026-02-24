// Data/FileSelectedTagsStore.swift

import Foundation

final class FileSelectedTagsStore: SelectedTagsStore {

    private let fileName = "selected_tags.json"

    func load() throws -> Set<String> {
        let url = try fileURL()
        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let tags = try decoder.decode([String].self, from: data)
        return Set(tags)
    }

    func save(_ tags: Set<String>) throws {
        let url = try fileURL()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(Array(tags).sorted())
        try data.write(to: url, options: [.atomic])
    }

    private func fileURL() throws -> URL {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(
                domain: "FileSelectedTagsStore",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Documents directory not found"]
            )
        }
        return docs.appendingPathComponent(fileName)
    }
}
