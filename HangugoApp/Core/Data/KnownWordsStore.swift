import Foundation

protocol KnownWordsStore {
    func load() throws -> Set<String>
    func save(_ ids: Set<String>) throws
}
