import Foundation

protocol WordsLoading {
    func loadWords() throws -> [Word]
}

struct BundledWordsLoaderAdapter: WordsLoading {
    func loadWords() throws -> [Word] {
        try BundledWordsLoader.loadWords()
    }
}
