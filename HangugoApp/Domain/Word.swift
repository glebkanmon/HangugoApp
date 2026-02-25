// Domain/Word.swift

import Foundation

struct Word: Identifiable, Codable, Equatable {
    let id: String
    let korean: String
    let transcriptionRR: String?
    let translation: String
    let example: String?
    let exampleTranslation: String?
    let imageAssetName: String?
    let audioKey: String?
    let tags: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case korean
        case transcriptionRR = "transcription_rr"
        case translation
        case example
        case exampleTranslation
        case imageAssetName
        case audioKey
        case tags
    }

    init(
        id: String,
        korean: String,
        transcriptionRR: String? = nil,
        translation: String,
        example: String? = nil,
        exampleTranslation: String? = nil,
        imageAssetName: String? = nil,
        audioKey: String? = nil,
        tags: [String]? = nil
    ) {
        self.id = id
        self.korean = korean
        self.transcriptionRR = transcriptionRR
        self.translation = translation
        self.example = example
        self.exampleTranslation = exampleTranslation
        self.imageAssetName = imageAssetName
        self.audioKey = audioKey
        self.tags = tags
    }
}
