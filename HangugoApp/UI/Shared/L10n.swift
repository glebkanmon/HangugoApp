// UI/Shared/L10n.swift

import Foundation

enum L10n {
    enum Common {
        static let wordSection = "Слово"
        static let exampleSection = "Пример"

        static let hintTapToRevealAll = "Нажми, чтобы показать перевод и картинку"
        static let hintTapToRevealTranslation = "Нажми, чтобы показать перевод"
    }

    enum Learn {
        static let navTitleNewWords = "Новые слова"

        static let progressPrefix = "Запомнил:"
        static let errorSection = "Ошибка"

        static let noNewWordsTitle = "Новых слов нет ✅"
        static let noNewWordsSubtitle = "Можно перейти в повторение или практику предложений."

        static let finishedTitle = "Сессия завершена ✅"
        static let finishedSubtitle = "Слова добавлены в повторение."

        static let loading = "Загружаем…"

        static let btnAlreadyKnow = "Уже знаю"
        static let btnStartLearning = "Начать учить"
        static let btnShowLater = "Показать ещё"
        static let btnMastered = "Запомнил(а)"
    }

    enum Review {
        static let navTitle = "Повторение"

        static let todaySection = "Сегодня"
        static let dueCountPrefix = "Карточек на сегодня:"

        static let doneTitle = "Готово ✅"
        static let doneSubtitle = "Можно перейти к практике предложений."
        static let goToPractice = "Перейти к практике"

        static let ratingSection = "Оценка"

        static let btnHard = "Сложно"
        static let btnNormal = "Нормально"
        static let btnEasy = "Легко"

        static let missingWord = "Не удалось найти слово для текущей карточки SRS."
    }

    enum Settings {
        static let navTitle = "Настройки"

        static let newWordsSessionSection = "Сессия новых слов"
        static let wordsPerSession = "Слов за сессию"

        static let firstReviewTomorrow = "Первое повторение — завтра"
        static let firstReviewTomorrowOnHint = "Слова попадут в повторение начиная с завтрашнего дня."
        static let firstReviewTomorrowOffHint = "Слова могут появиться в повторении уже сегодня."
    }

    enum Words {
        static let navTitleAllWords = "Все слова"
        static let searchPlaceholder = "Поиск"
        static let empty = "Ничего не найдено"
    }

    enum WordDetail {
        static let translationSection = "Перевод"
        static let imageSection = "Картинка"
        static let practiceSection = "Практика"
        static let tryInPractice = "Попробовать в практике"
        static let noExample = "Пример не задан"
    }
}
