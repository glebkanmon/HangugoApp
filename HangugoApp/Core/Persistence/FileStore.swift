import Foundation

/// Low-level file persistence helper:
/// - reads/writes JSON
/// - atomic writes (temp + replace)
/// - optional schema envelope with migration from legacy payload
final class FileStore {

    struct Envelope<T: Codable>: Codable {
        let schemaVersion: Int
        let payload: T
    }

    enum StoreError: Error, LocalizedError {
        case failedToCreateDirectory(URL)
        case failedToWrite(URL, underlying: Error)
        case failedToReplace(URL, underlying: Error)
        case failedToRead(URL, underlying: Error)
        case failedToDecode(URL, underlying: Error)

        var errorDescription: String? {
            switch self {
            case .failedToCreateDirectory(let url):
                return "Не удалось создать директорию: \(url.path)"
            case .failedToWrite(let url, let underlying):
                return "Не удалось записать файл: \(url.lastPathComponent). \(underlying.localizedDescription)"
            case .failedToReplace(let url, let underlying):
                return "Не удалось заменить файл: \(url.lastPathComponent). \(underlying.localizedDescription)"
            case .failedToRead(let url, let underlying):
                return "Не удалось прочитать файл: \(url.lastPathComponent). \(underlying.localizedDescription)"
            case .failedToDecode(let url, let underlying):
                return "Не удалось декодировать файл: \(url.lastPathComponent). \(underlying.localizedDescription)"
            }
        }
    }

    private let fileManager: FileManager
    private let baseURL: URL

    init(
        fileManager: FileManager = .default,
        baseDirectory: URL? = nil,
        subdirectory: String? = nil
    ) throws {
        self.fileManager = fileManager

        let docs = baseDirectory ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        if let subdirectory {
            self.baseURL = docs.appendingPathComponent(subdirectory, isDirectory: true)
        } else {
            self.baseURL = docs
        }

        if !fileManager.fileExists(atPath: baseURL.path) {
            do {
                try fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
            } catch {
                throw StoreError.failedToCreateDirectory(baseURL)
            }
        }
    }

    func url(for filename: String) -> URL {
        baseURL.appendingPathComponent(filename, isDirectory: false)
    }

    func exists(_ filename: String) -> Bool {
        fileManager.fileExists(atPath: url(for: filename).path)
    }

    // MARK: - JSON Read/Write

    func readJSON<T: Decodable>(_ filename: String, as type: T.Type) throws -> T {
        let fileURL = url(for: filename)

        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw StoreError.failedToRead(fileURL, underlying: error)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw StoreError.failedToDecode(fileURL, underlying: error)
        }
    }

    /// Atomic JSON write:
    /// 1) write to temp file in same directory
    /// 2) replace original (or move into place)
    func writeJSONAtomic<T: Encodable>(_ value: T, to filename: String) throws {
        let fileURL = url(for: filename)
        let dirURL = fileURL.deletingLastPathComponent()

        let data: Data
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            data = try encoder.encode(value)
        } catch {
            throw StoreError.failedToWrite(fileURL, underlying: error)
        }

        let tempURL = dirURL.appendingPathComponent(".\(fileURL.lastPathComponent).tmp-\(UUID().uuidString)")

        do {
            try data.write(to: tempURL, options: [.atomic])
        } catch {
            throw StoreError.failedToWrite(tempURL, underlying: error)
        }

        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                _ = try fileManager.replaceItemAt(fileURL, withItemAt: tempURL, backupItemName: nil, options: .usingNewMetadataOnly)
            } else {
                try fileManager.moveItem(at: tempURL, to: fileURL)
            }
        } catch {
            // если replace/move упал — пробуем подчистить temp
            try? fileManager.removeItem(at: tempURL)
            throw StoreError.failedToReplace(fileURL, underlying: error)
        }
    }

    // MARK: - Envelope helpers

    /// Reads `Envelope<T>` if possible, otherwise tries legacy `T`.
    /// If legacy is read successfully, it is automatically migrated and saved as Envelope.
    func readEnvelopeOrLegacy<T: Codable>(
        filename: String,
        schemaVersion: Int,
        legacyType: T.Type = T.self
    ) throws -> Envelope<T> {
        let fileURL = url(for: filename)

        // 1) Try envelope
        if exists(filename) {
            do {
                let env = try readJSON(filename, as: Envelope<T>.self)
                return env
            } catch {
                // ignore and try legacy
            }
        }

        // 2) Try legacy
        let legacy: T
        do {
            legacy = try readJSON(filename, as: legacyType)
        } catch {
            throw StoreError.failedToDecode(fileURL, underlying: error)
        }

        // 3) Migrate
        let env = Envelope(schemaVersion: schemaVersion, payload: legacy)
        try writeJSONAtomic(env, to: filename)
        return env
    }
}
