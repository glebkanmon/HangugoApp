// Domain/SelectedTagsService.swift

import Foundation

final class SelectedTagsService {
    private let store: SelectedTagsStore
    private(set) var tags: Set<String> = []

    init(store: SelectedTagsStore) {
        self.store = store
    }

    func load() throws {
        tags = try store.load()
    }

    func set(_ newTags: Set<String>) throws {
        tags = newTags
        try store.save(tags)
    }

    func reset() throws {
        try set([])
    }
}
