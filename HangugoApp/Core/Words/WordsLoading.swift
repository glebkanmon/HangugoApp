import Foundation

protocol WordsLoading {
    func loadWords() async throws -> [Word]
}

struct BundledWordsLoaderAdapter: WordsLoading {
    func loadWords() async throws -> [Word] {
        try BundledWordsLoader.loadWords()
    }
}
