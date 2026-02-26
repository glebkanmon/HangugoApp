import Foundation
import FirebaseFirestore

final class FirestoreWordsLoader: WordsLoading {
    func loadWords() async throws -> [Word] {
        let db = Firestore.firestore()
        let snapshot = try await db.collection("words").getDocuments()

        let words = try snapshot.documents.compactMap { document -> Word? in
            let data = document.data()

            let id: String
            if let rawId = data["id"] as? String,
               !rawId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                id = rawId
            } else {
                id = document.documentID
            }

            guard
                let korean = data["korean"] as? String,
                let translation = data["translation"] as? String
            else {
                throw NSError(
                    domain: "FirestoreWordsLoader",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid word document: \(document.documentID)"]
                )
            }

            let transcriptionRR = data["transcription_rr"] as? String
            let example = data["example"] as? String
            let exampleTranslation = data["exampleTranslation"] as? String
            let imageAssetName = data["imageAssetName"] as? String
            let audioKey = data["audioKey"] as? String
            let tags = data["tags"] as? [String]

            return Word(
                id: id,
                korean: korean,
                transcriptionRR: transcriptionRR,
                translation: translation,
                example: example,
                exampleTranslation: exampleTranslation,
                imageAssetName: imageAssetName,
                audioKey: audioKey,
                tags: tags
            )
        }

        return words.sorted { $0.korean < $1.korean }
    }
}
