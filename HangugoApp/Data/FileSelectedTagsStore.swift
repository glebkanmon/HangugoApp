import Foundation

final class FileSelectedTagsStore: SelectedTagsStore {

    private static let filename = "selected_tags.json"
    private static let schemaVersion = 1

    private let store: FileStore

    init() {
        self.store = (try? FileStore()) ?? (try! FileStore(baseDirectory: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!))
    }

    // MARK: - SelectedTagsStore

    func load() throws -> Set<String> {
        guard store.exists(Self.filename) else { return [] }

        // legacy: [String]
        let env = try store.readEnvelopeOrLegacy(
            filename: Self.filename,
            schemaVersion: Self.schemaVersion,
            legacyType: [String].self
        )
        return Set(env.payload)
    }

    func save(_ tags: Set<String>) throws {
        let payload = Array(tags).sorted()
        let env = FileStore.Envelope(schemaVersion: Self.schemaVersion, payload: payload)
        try store.writeJSONAtomic(env, to: Self.filename)
    }
}
