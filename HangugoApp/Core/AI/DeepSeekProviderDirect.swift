import Foundation

/// ⚠️ DEV ONLY.
/// Do NOT ship API keys inside the app for production.
/// For production: iOS -> your backend -> DeepSeek.
final class DeepSeekProviderDirect: LLMProvider {

    enum DeepSeekError: LocalizedError {
        case invalidResponse
        case httpStatus(code: Int, body: String)
        case emptyContent
        case truncated

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "DeepSeek: invalid response."
            case .httpStatus(let code, let body):
                return "DeepSeek HTTP \(code): \(body)"
            case .emptyContent:
                return "DeepSeek: empty assistant content."
            case .truncated:
                return "DeepSeek: ответ обрезан (finish_reason=length). Увеличьте max_tokens или сократите ответ."
            }
        }
    }

    private let apiKey: String
    private let session: URLSession
    private let baseURL: URL

    init(
        apiKey: String,
        baseURL: URL = URL(string: "https://api.deepseek.com")!,
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.session = session
    }
    
    func checkSentenceJSON(koreanInput: String, includeStage2: Bool) async throws -> String {
        // 1) пробуем обычным лимитом
        do {
            return try await requestOnce(
                koreanInput: koreanInput,
                includeStage2: includeStage2,
                maxTokens: includeStage2 ? 3000 : 1500
            )
        } catch DeepSeekError.truncated {
            // 2) если обрезало — ретрай с большим лимитом
            return try await requestOnce(
                koreanInput: koreanInput,
                includeStage2: includeStage2,
                maxTokens: 4096
            )
        }
    }
    private func requestOnce(koreanInput: String, includeStage2: Bool, maxTokens: Int) async throws -> String {
        let model = includeStage2 ? "deepseek-reasoner" : "deepseek-chat"
        let url = baseURL.appendingPathComponent("chat/completions")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let system = Self.systemPromptAIResultJSON()
        let user = Self.userPrompt(sentence: koreanInput, includeStage2: includeStage2)

        let body = DeepSeekChatRequest(
            model: model,
            messages: [
                .init(role: "system", content: system),
                .init(role: "user", content: user)
            ],
            stream: false,
            temperature: 0.0,          // ✅ для JSON лучше 0
            max_tokens: maxTokens
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw DeepSeekError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            throw DeepSeekError.httpStatus(code: http.statusCode, body: bodyText)
        }

        let decoded = try JSONDecoder().decode(DeepSeekChatResponse.self, from: data)
        let choice = decoded.choices.first

        // ✅ детект обрезки
        if choice?.finish_reason == "length" {
            throw DeepSeekError.truncated
        }

        let msg = choice?.message
        let primary = msg?.content?.trimmingCharacters(in: .whitespacesAndNewlines)
        let reasoning = msg?.reasoning_content?.trimmingCharacters(in: .whitespacesAndNewlines)

        let raw = (primary?.isEmpty == false ? primary : nil)
               ?? (reasoning?.isEmpty == false ? reasoning : nil)

        guard let rawText = raw else {
            throw DeepSeekError.emptyContent
        }

        guard let json = Self.extractJSONObject(from: rawText) else {
            #if DEBUG
            print("⚠️ DeepSeek raw text (first 800 chars):")
            print(String(rawText.prefix(800)))
            #endif
            throw DeepSeekError.httpStatus(code: 200, body: "Model did not return a JSON object.")
        }

        return json
    }



//    func checkSentenceJSON(koreanInput: String, includeStage2: Bool) async throws -> String {
//        // DeepSeek models
//        let model = includeStage2 ? "deepseek-reasoner" : "deepseek-chat"
//
//        // Endpoint: /chat/completions (OpenAI-compatible)
//        // Docs also mention /v1 compatibility; /chat/completions works on base URL. :contentReference[oaicite:3]{index=3}
//        let url = baseURL.appendingPathComponent("chat/completions")
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization") // Bearer auth :contentReference[oaicite:4]{index=4}
//
//        let system = Self.systemPromptAIResultJSON()
//        let user = Self.userPrompt(sentence: koreanInput, includeStage2: includeStage2)
//
//        let body = DeepSeekChatRequest(
//            model: model,
//            messages: [
//                .init(role: "system", content: system),
//                .init(role: "user", content: user)
//            ],
//            stream: false,
//            temperature: 0.2,
//            max_tokens: 1400
//        )
//
//        request.httpBody = try JSONEncoder().encode(body)
//
//        let (data, response) = try await session.data(for: request)
//
//        guard let http = response as? HTTPURLResponse else {
//            throw DeepSeekError.invalidResponse
//        }
//
//        guard (200...299).contains(http.statusCode) else {
//            let bodyText = String(data: data, encoding: .utf8) ?? ""
//            // DeepSeek typical errors: 402/422/429/503 etc. :contentReference[oaicite:5]{index=5}
//            throw DeepSeekError.httpStatus(code: http.statusCode, body: bodyText)
//        }
//
//        let decoded = try JSONDecoder().decode(DeepSeekChatResponse.self, from: data)
//        let msg = decoded.choices.first?.message
//
//        let primary = msg?.content?.trimmingCharacters(in: .whitespacesAndNewlines)
//        let reasoning = msg?.reasoning_content?.trimmingCharacters(in: .whitespacesAndNewlines)
//
//        // ✅ Для reasoner: если content пустой, берём reasoning_content :contentReference[oaicite:2]{index=2}
//        let rawText = (primary?.isEmpty == false ? primary : nil)
//                  ?? (reasoning?.isEmpty == false ? reasoning : nil)
//
//        guard let raw = rawText else {
//            #if DEBUG
//            print("⚠️ DeepSeek message.content and message.reasoning_content are empty.")
//            #endif
//            throw DeepSeekError.emptyContent
//        }
//
//        // ✅ Всегда возвращаем только JSON (если не нашли — кинем ошибку)
//        guard let json = Self.extractJSONObject(from: raw) else {
//            #if DEBUG
//            print("⚠️ DeepSeek raw text (first 800 chars):")
//            print(String(raw.prefix(800)))
//            #endif
//            throw DeepSeekError.httpStatus(code: 200, body: "Model did not return a JSON object.")
//        }
//
//        return json
//    }
}

// MARK: - OpenAI-compatible request/response

private struct DeepSeekChatRequest: Encodable {
    struct Message: Encodable {
        let role: String   // "system" | "user" | "assistant"
        let content: String
    }

    let model: String
    let messages: [Message]
    let stream: Bool
    let temperature: Double?
    let max_tokens: Int?
}

private struct DeepSeekChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let role: String
            let content: String?
            let reasoning_content: String?   // ✅ для deepseek-reasoner :contentReference[oaicite:1]{index=1}
        }
        let index: Int
        let message: Message
        let finish_reason: String?
    }

    let choices: [Choice]
}

// MARK: - Prompts + JSON extraction

private extension DeepSeekProviderDirect {

    static func systemPromptAIResultJSON() -> String {
        """
        You are a Korean language tutor.

        Output MUST be ONLY a single valid JSON object.
        Do NOT output markdown. Do NOT wrap in code fences. Do NOT add any extra text.

        JSON schema (must match exactly, keep keys in English as shown):

        {
          "stage1": {
            "isCorrect": true|false,
            "corrected": string|null,
            "mistakes": [
              { "id": string, "type": string, "explanationRu": string, "suggestionRu": string|null }
            ],
            "literalMeaningRu": string|null,
            "naturalTranslationRu": string|null,
            "shortRuleRu": string|null
          },
          "stage2": null | {
            "nativeIntentRu": string,
            "whyThisFormRu": string,
            "alternatives": [
              { "id": string, "korean": string, "nuanceRu": string }
            ],
            "selfCheckRu": string|null
          },
          "meta": {
            "score": integer,
            "confidence": number,
            "model": string
          }
        }

        Language: explanations MUST be in Russian (Ru fields).
        Keep it concise. Ensure JSON is valid.
        """
    }

    static func userPrompt(sentence: String, includeStage2: Bool) -> String {
        """
        Task:
        1) Check the Korean sentence for grammar and naturalness.
        2) Provide corrections and mistakes.
        3) Provide translations.

        Sentence:
        \(sentence)

        Include stage2:
        \(includeStage2 ? "YES" : "NO")
        """
    }

    /// Extracts the first top-level JSON object `{ ... }` from text.
    /// Returns nil if not found.
    static func extractJSONObject(from text: String) -> String? {
        // Найдём первую '{'
        guard let firstBrace = text.firstIndex(of: "{") else { return nil }

        var depth = 0
        var start: String.Index?

        for i in text[firstBrace...].indices {
            let ch = text[i]
            if ch == "{" {
                if depth == 0 { start = i }
                depth += 1
            } else if ch == "}" {
                guard depth > 0 else { continue }
                depth -= 1
                if depth == 0, let s = start {
                    let candidate = String(text[s...i])

                    // Валидация: должен быть валидный JSON объект
                    if let data = candidate.data(using: .utf8),
                       (try? JSONSerialization.jsonObject(with: data, options: [])) != nil {
                        return candidate
                    } else {
                        return nil
                    }
                }
            }
        }

        return nil
    }
}
