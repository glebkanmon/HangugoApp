import Foundation

struct Word: Identifiable, Codable, Hashable {
    let id: String                 // стабильный id из JSON
    let korean: String
    let translation: String

    // Пример
    let example: String?
    let exampleTranslation: String?   // ✅ перевод примера (RU)

    // MVP-friendly расширения
    let imageAssetName: String?    // ассоциативная картинка в Assets
    let audioKey: String?          // позже: ключ/путь к аудио
    let tags: [String]?
}
