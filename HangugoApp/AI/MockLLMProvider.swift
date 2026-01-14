import Foundation

final class MockLLMProvider: LLMProvider {

    func checkSentenceJSON(koreanInput: String, includeStage2: Bool) async throws -> String {
        try await Task.sleep(nanoseconds: 250_000_000)

        let normalized = koreanInput.replacingOccurrences(of: " ", with: "")

        if normalized.contains("밥을먹어요") {
            return """
            {
              "stage1": {
                "isCorrect": true,
                "corrected": null,
                "mistakes": [],
                "literalMeaningRu": "Я ем рис/еду.",
                "naturalTranslationRu": "Я ем.",
                "shortRuleRu": "Глагол + 어요/아요 — базовый вежливый стиль."
              },
              "stage2": \(includeStage2 ? """
              {
                "nativeIntentRu": "Носитель понимает: вы описываете привычное действие.",
                "whyThisFormRu": "먹어요 звучит нейтрально-вежливо и подходит в большинстве бытовых ситуаций.",
                "alternatives": [
                  { "id": "alt_1", "korean": "밥 먹어요.", "nuanceRu": "Разговорно, частицы часто опускают." },
                  { "id": "alt_2", "korean": "저는 밥을 먹습니다.", "nuanceRu": "Формально (습니다-стиль)." }
                ],
                "selfCheckRu": "Форма 먹어요 и порядок слов корректны."
              }
              """ : "null"),
              "meta": { "score": 92, "confidence": 0.82, "model": "\(includeStage2 ? "mock-stage1+stage2" : "mock-stage1")" }
            }
            """
        }

        if normalized.contains("밥먹어요") {
            return """
            {
              "stage1": {
                "isCorrect": true,
                "corrected": "밥 먹어요.",
                "mistakes": [],
                "literalMeaningRu": "Я ем рис/еду.",
                "naturalTranslationRu": "Я ем.",
                "shortRuleRu": "В разговорной речи частицы часто опускают."
              },
              "stage2": \(includeStage2 ? """
              {
                "nativeIntentRu": "Звучит как обычная бытовая фраза.",
                "whyThisFormRu": "Без частиц — более разговорно, но естественно в контексте.",
                "alternatives": [
                  { "id": "alt_1", "korean": "밥을 먹어요.", "nuanceRu": "Чуть аккуратнее/полнее." },
                  { "id": "alt_2", "korean": "저는 밥을 먹어요.", "nuanceRu": "С 강조: 'я' как тема." }
                ],
                "selfCheckRu": "Ошибок нет, это допустимая разговорная форма."
              }
              """ : "null"),
              "meta": { "score": 88, "confidence": 0.78, "model": "\(includeStage2 ? "mock-stage1+stage2" : "mock-stage1")" }
            }
            """
        }

        return """
        {
          "stage1": {
            "isCorrect": false,
            "corrected": "저는 영화를 봐요.",
            "mistakes": [
              {
                "id": "m_001",
                "type": "word_order",
                "explanationRu": "В корейском обычно: тема/подлежащее → дополнение → глагол.",
                "suggestionRu": "Попробуй: 저는 영화를 봐요."
              }
            ],
            "literalMeaningRu": "Я смотрю фильм.",
            "naturalTranslationRu": "Я смотрю кино.",
            "shortRuleRu": "Порядок слов: тема/подлежащее → объект → сказуемое."
          },
          "stage2": \(includeStage2 ? """
          {
            "nativeIntentRu": "Носитель восстанавливает намерение: вы хотели сказать, что смотрите фильм.",
            "whyThisFormRu": "은/는 — тема, 를 — объект, 봐요 — нейтрально-вежливо.",
            "alternatives": [
              { "id": "alt_1", "korean": "영화 봐요.", "nuanceRu": "Очень разговорно и коротко." },
              { "id": "alt_2", "korean": "저 영화 봐요.", "nuanceRu": "Лёгкий разговорный оттенок." }
            ],
            "selfCheckRu": "Исправление сохраняет смысл и делает фразу стандартной."
          }
          """ : "null"),
          "meta": { "score": 55, "confidence": 0.62, "model": "\(includeStage2 ? "mock-stage1+stage2" : "mock-stage1")" }
        }
        """
    }
}
