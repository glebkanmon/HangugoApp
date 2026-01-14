import Foundation

protocol SRSStore {
    func load() throws -> [SRSItem]
    func save(_ items: [SRSItem]) throws
}
