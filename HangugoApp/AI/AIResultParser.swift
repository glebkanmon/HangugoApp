import Foundation

enum AIResultParser {
    static func decode(from json: String) throws -> AIResult {
        let data = Data(json.utf8)
        let decoder = JSONDecoder()
        return try decoder.decode(AIResult.self, from: data)
    }
}
