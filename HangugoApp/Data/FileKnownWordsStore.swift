import Foundation

final class FileKnownWordsStore: KnownWordsStore {

    private static let filename = "known_word_ids.json"
    private static let schemaVersion = 1

    private let store: FileStore

    init() {
        self.store = (try? FileStore()) ?? (try! FileStore(baseDirectory: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!))
    }

    // MARK: - KnownWordsStore

    func load() throws -> Set<String> {
        guard store.exists(Self.filename) else { return [] }

        // legacy: [String]
        let env = try store.readEnvelopeOrLegacy(
            filename: Self.filename,
            schemaVersion: Self.schemaVersion,
            legacyType: [String].self
        )

        // payload в envelope — Set<String>
        // но если legacy был [String], envelope уже будет мигрирован как [String] → тут надо привести.
        // Чтобы schema был стабильным, храним payload в Set<String> в envelope.
        //
        // Поэтому: если файл был legacy, env.payload фактически будет [String] только на этапе readLegacy,
        // но мы мигрируем его как Envelope<T> где T == legacyType. Тут нам нужен стабильный формат.
        //
        // Решение: читаем envelope именно как Envelope<[String]> и приводим к Set.
        // Если файл уже новый, он будет Envelope<[String]>; это нормально и проще.
        return Set(env.payload)
    }

    func save(_ ids: Set<String>) throws {
        // Храним как [String] (детерминированнее, проще миграции/диффов)
        let payload = Array(ids).sorted()
        let env = FileStore.Envelope(schemaVersion: Self.schemaVersion, payload: payload)
        try store.writeJSONAtomic(env, to: Self.filename)
    }
}
