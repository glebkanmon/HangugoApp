import Foundation
import FirebaseFirestore

struct FirebaseWordsSeedResult {
    let createdCount: Int
    let updatedCount: Int
    let skippedRemoteDuplicateCount: Int
    let skippedLocalDuplicateCount: Int

    var summary: String {
        """
        Готово.
        Создано: \(createdCount)
        Обновлено по id: \(updatedCount)
        Пропущено как дубль в Firebase: \(skippedRemoteDuplicateCount)
        Пропущено как дубль в words.json: \(skippedLocalDuplicateCount)
        """
    }
}

final class FirebaseWordsSeeder {
    private let wordsCollection = "words"
    private let dedupeIndexCollection = "word_dedupe_index"

    func seedFromBundle() async throws -> FirebaseWordsSeedResult {
        let db = Firestore.firestore()
        let localWords = try BundledWordsLoader.loadWords()

        var seenLocalDedupeKeys = Set<String>()

        var createdCount = 0
        var updatedCount = 0
        var skippedRemoteDuplicateCount = 0
        var skippedLocalDuplicateCount = 0

        for word in localWords {
            guard let dedupeKey = WordDedupeKey.make(korean: word.korean, translation: word.translation) else {
                continue
            }

            if seenLocalDedupeKeys.contains(dedupeKey) {
                skippedLocalDuplicateCount += 1
                continue
            }
            seenLocalDedupeKeys.insert(dedupeKey)

            let dedupeDocID = WordDedupeKey.hashDocumentID(for: dedupeKey)
            let wordRef = db.collection(wordsCollection).document(word.id)
            let indexRef = db.collection(dedupeIndexCollection).document(dedupeDocID)

            let wordSnapshot = try await wordRef.getDocument()

            let wordPayload = try makeWordFirestoreData(from: word, dedupeKey: dedupeKey)
            let indexPayload = makeIndexFirestoreData(
                dedupeKey: dedupeKey,
                wordID: word.id,
                korean: word.korean,
                translation: word.translation
            )

            // Документ с таким id уже есть -> обновляем слово и индекс
            if wordSnapshot.exists {
                let batch = db.batch()
                batch.setData(wordPayload, forDocument: wordRef)
                batch.setData(indexPayload, forDocument: indexRef)
                try await batch.commit()

                updatedCount += 1
                continue
            }

            // Иначе проверяем, занят ли dedupeKey
            let indexSnapshot = try await indexRef.getDocument()

            if indexSnapshot.exists {
                skippedRemoteDuplicateCount += 1
                continue
            }

            let batch = db.batch()
            batch.setData(wordPayload, forDocument: wordRef)
            batch.setData(indexPayload, forDocument: indexRef)
            try await batch.commit()

            createdCount += 1
        }

        return FirebaseWordsSeedResult(
            createdCount: createdCount,
            updatedCount: updatedCount,
            skippedRemoteDuplicateCount: skippedRemoteDuplicateCount,
            skippedLocalDuplicateCount: skippedLocalDuplicateCount
        )
    }
}

// MARK: - Helpers

private extension FirebaseWordsSeeder {
    func makeWordFirestoreData(from word: Word, dedupeKey: String) throws -> [String: Any] {
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(word)

        guard
            let rawObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        else {
            throw NSError(
                domain: "FirebaseWordsSeeder",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to serialize Word to Firestore payload"]
            )
        }

        var payload = removeNulls(from: rawObject)
        payload["dedupeKey"] = dedupeKey
        payload["updatedAt"] = FieldValue.serverTimestamp()
        return payload
    }

    func makeIndexFirestoreData(
        dedupeKey: String,
        wordID: String,
        korean: String,
        translation: String
    ) -> [String: Any] {
        [
            "dedupeKey": dedupeKey,
            "wordId": wordID,
            "korean": korean,
            "translation": translation,
            "updatedAt": FieldValue.serverTimestamp()
        ]
    }

    func removeNulls(from dictionary: [String: Any]) -> [String: Any] {
        var cleaned: [String: Any] = [:]

        for (key, value) in dictionary {
            if value is NSNull { continue }
            cleaned[key] = value
        }

        return cleaned
    }
}
