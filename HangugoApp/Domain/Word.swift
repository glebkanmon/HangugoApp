import Foundation

import Foundation

struct Word: Identifiable, Codable, Hashable {
    let id: String                 // стабильный id из JSON
    let korean: String
    let translation: String

    // MVP-friendly расширения
    let example: String?
    let imageAssetName: String?    // ассоциативная картинка в Assets
    let audioKey: String?          // позже: ключ/путь к аудио
    let tags: [String]?
}
