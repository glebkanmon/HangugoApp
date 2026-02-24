import Foundation

final class KnownWordsService {

    private let store: KnownWordsStore
    private var cached: Set<String> = []

    init(store: KnownWordsStore) {
        self.store = store
    }

    func load() throws {
        cached = try store.load()
    }

    func persist() throws {
        try store.save(cached)
    }

    func contains(_ wordId: String) -> Bool {
        cached.contains(wordId)
    }

    func addKnown(wordId: String) {
        cached.insert(wordId)
    }

    func allWordIds() -> [String] {
        Array(cached)
    }
}
