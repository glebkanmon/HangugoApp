import Foundation

struct SRSItem: Identifiable, Codable, Hashable {
    var id: String { wordId }      // удобно: один SRSItem на слово
    let wordId: String

    var repetitions: Int
    var intervalDays: Int
    var easeFactor: Double
    var dueDate: Date
    var lapses: Int
    var lastReviewedAt: Date?
}
