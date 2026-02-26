import Foundation

final class FallbackWordsLoader: WordsLoading {
    private let primary: WordsLoading
    private let fallback: WordsLoading

    init(primary: WordsLoading, fallback: WordsLoading) {
        self.primary = primary
        self.fallback = fallback
    }

    func loadWords() async throws -> [Word] {
        do {
            let words = try await primary.loadWords()
            if words.isEmpty {
                return try await fallback.loadWords()
            }
            return words
        } catch {
            return try await fallback.loadWords()
        }
    }
}
