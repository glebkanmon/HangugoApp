// Data/SelectedTagsStore.swift

import Foundation

protocol SelectedTagsStore {
    func load() throws -> Set<String>
    func save(_ tags: Set<String>) throws
}
