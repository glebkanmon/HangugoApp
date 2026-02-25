import Foundation

final class FileSRSStore: SRSStore {

    private static let filename = "srs_items.json"
    private static let schemaVersion = 1

    private let store: FileStore

    init() {
        // Фоллбек без крэша: если директория не создалась — используем Documents напрямую.
        // В реальности ошибка крайне редкая, но так VM/Service не упадут на init.
        self.store = (try? FileStore()) ?? (try! FileStore(baseDirectory: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!))
    }

    // MARK: - SRSStore

    func load() throws -> [SRSItem] {
        guard store.exists(Self.filename) else { return [] }

        let env = try store.readEnvelopeOrLegacy(
            filename: Self.filename,
            schemaVersion: Self.schemaVersion,
            legacyType: [SRSItem].self
        )
        return env.payload
    }

    func save(_ items: [SRSItem]) throws {
        let env = FileStore.Envelope(schemaVersion: Self.schemaVersion, payload: items)
        try store.writeJSONAtomic(env, to: Self.filename)
    }
}
