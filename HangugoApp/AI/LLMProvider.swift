import Foundation

protocol LLMProvider {
    func checkSentenceJSON(koreanInput: String, includeStage2: Bool) async throws -> String
}
