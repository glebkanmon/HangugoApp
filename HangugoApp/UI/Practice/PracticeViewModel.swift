import Foundation
import Combine

@MainActor
final class PracticeViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var result: AIResult?
    @Published var errorMessage: String?

    // ✅ “Текст изменён после проверки”
    @Published var isResultStale: Bool = false

    private let provider: LLMProvider
    private var cancellables = Set<AnyCancellable>()

    // Для Recheck
    private var lastCheckedText: String?
    private var lastIncludeStage2: Bool = false

    init(provider: LLMProvider = DeepSeekProviderDirect(apiKey: Secrets.deepSeekApiKey)) {
        self.provider = provider

        // Отслеживаем изменения input -> помечаем результат как “устаревший”
        $inputText
            .dropFirst()
            .sink { [weak self] newValue in
                guard let self else { return }
                self.updateStaleState(for: newValue)
            }
            .store(in: &cancellables)
    }

    // MARK: - Derived

    var correctedText: String? {
        guard let text = result?.stage1.corrected, !text.isEmpty else { return nil }
        return text
    }

    var canRecheck: Bool {
        result != nil && isResultStale && !isLoading
    }

    var lastModeLabel: String {
        lastIncludeStage2 ? "Deep" : "Check"
    }

    // MARK: - Actions

    func applyCorrection() {
        guard let correctedText else { return }
        inputText = correctedText
    }

    func prefill(from word: Word?) {
        guard let word else { return }
        if let example = word.example, !example.isEmpty {
            inputText = example
        } else {
            inputText = word.korean
        }
    }

    func recheck() async {
        await check(includeStage2: lastIncludeStage2)
    }

    func check(includeStage2: Bool) async {
        guard !isLoading else { return }

        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let json = try await provider.checkSentenceJSON(koreanInput: text, includeStage2: includeStage2)
            let res = try AIResultParser.decode(from: json)

            // ✅ сохраняем baseline для “устарел/не устарел”
            lastCheckedText = text
            lastIncludeStage2 = includeStage2

            result = res
            isResultStale = false
        } catch {
            errorMessage = "Ошибка формата ответа (JSON). \(error.localizedDescription)"
        }
    }

    // MARK: - Private

    private func updateStaleState(for newInput: String) {
        guard result != nil else {
            isResultStale = false
            return
        }
        guard let lastCheckedText else {
            isResultStale = false
            return
        }

        let current = newInput.trimmingCharacters(in: .whitespacesAndNewlines)
        isResultStale = (current != lastCheckedText)
    }
}
