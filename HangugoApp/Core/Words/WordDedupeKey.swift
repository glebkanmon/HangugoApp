import Foundation
import CryptoKit

enum WordDedupeKey {
    static func make(korean: String?, translation: String?) -> String? {
        guard
            let koreanPart = korean?.normalizedNonEmpty?.lowercased(),
            let translationPart = translation?.normalizedNonEmpty?.lowercased()
        else {
            return nil
        }

        return "\(koreanPart)|\(translationPart)"
    }

    static func hashDocumentID(for dedupeKey: String) -> String {
        let digest = SHA256.hash(data: Data(dedupeKey.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
