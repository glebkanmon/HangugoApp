
import Foundation
import Combine

@MainActor
final class PracticeViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var result: AIResult?
    @Published var errorMessage: String?

    private let provider: LLMProvider

    init(provider: LLMProvider = DeepSeekProviderDirect(apiKey: Secrets.deepSeekApiKey)) {
        self.provider = provider
    }

    func prefill(from word: Word?) {
        guard let word else { return }
        if let example = word.example, !example.isEmpty {
            inputText = example
        } else {
            inputText = word.korean
        }
    }

    func check(includeStage2: Bool) async {
        // ✅ защита от повторных нажатий
        guard !isLoading else { return }

        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let json = try await provider.checkSentenceJSON(koreanInput: text, includeStage2: includeStage2)
            let res = try AIResultParser.decode(from: json)
            result = res
        } catch {
            errorMessage = "Ошибка формата ответа (JSON). \(error.localizedDescription)"
        }
    }
}

