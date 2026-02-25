import Foundation

struct AIResult: Codable, Hashable {
    let stage1: Stage1Result
    let stage2: Stage2Result?
    let meta: Meta

    struct Stage1Result: Codable, Hashable {
        let isCorrect: Bool
        let corrected: String?
        let mistakes: [Mistake]
        let literalMeaningRu: String?
        let naturalTranslationRu: String?
        let shortRuleRu: String?
    }

    struct Mistake: Codable, Hashable, Identifiable {
        let id: String
        let type: String              // e.g. "particle", "word_order", "tense"
        let explanationRu: String
        let suggestionRu: String?
    }

    struct Stage2Result: Codable, Hashable {
        let nativeIntentRu: String
        let whyThisFormRu: String
        let alternatives: [Alternative]
        let selfCheckRu: String?
    }

    struct Alternative: Codable, Hashable, Identifiable {
        let id: String
        let korean: String
        let nuanceRu: String
    }

    struct Meta: Codable, Hashable {
        let score: Int                // 0...100
        let confidence: Double        // 0...1
        let model: String
    }
}
