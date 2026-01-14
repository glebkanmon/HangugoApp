import Foundation

enum BundledWordsLoader {
    static func loadWords() throws -> [Word] {
        guard let url = Bundle.main.url(forResource: "words", withExtension: "json") else {
            throw NSError(domain: "BundledWordsLoader", code: 1, userInfo: [NSLocalizedDescriptionKey: "words.json not found in bundle"])
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode([Word].self, from: data)
    }
}
