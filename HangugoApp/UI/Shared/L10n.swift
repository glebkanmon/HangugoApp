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
        static let navTitle = "Изучение"
        static let sessionsSection = "Сессии"
        static let newWords = "Новые слова"
        static let reviewToday = "Повторить сегодня"

        static let filtersSection = "Фильтры"
        static let categories = "Категории"
        static let categoriesAll = "Все"
        static let categoriesSelectedFormat = "Выбрано: %d"

        static let hangulSection = "Хангыль"
        static let soonAlphabet = "Алфавит (скоро)"
        static let soonSyllables = "Слоги (скоро)"
        static let soonReading = "Чтение (скоро)"

        static let wordsSection = "Слова"
        static let allWords = "Все слова"
        static let loading = "Загрузка…"
    }

    enum NewWordsSession {
        static let navTitle = "Новые слова"
        static let progressPrefix = "Запомнил:"
        static let errorSection = "Ошибка"

        static let noNewWordsTitle = "Новых слов нет ✅"
        static let noNewWordsSubtitle = "В выбранных категориях новых слов нет. Попробуй изменить категории или перейти в повторение."

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

    enum Categories {
        static let navTitle = "Категории"
        static let reset = "Сбросить фильтры"

        static let topicsSection = "Темы"
        static let posSection = "Части речи"
        static let listsSection = "Подборки"

        static let allHint = "Если ничего не выбрано — используются все слова."

        // Display names for tag values
        static func displayName(for tag: String) -> String {
            let parts = tag.split(separator: ":", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { return tag }
            let ns = parts[0], val = parts[1]

            switch ns {
            case "topic":
                switch val {
                case "daily": return "Быт"
                case "food": return "Еда"
                case "travel": return "Путешествия"
                case "time": return "Время"
                case "study": return "Учёба"
                case "work": return "Работа"
                case "description": return "Описание"
                case "weather": return "Погода"
                case "family": return "Семья"
                case "city": return "Город"
                case "shopping": return "Покупки"
                case "animals": return "Животные"
                case "weekdays": return "Дни недели"
                case "months": return "Месяцы"
                case "seasons": return "Времена года"
                case "money": return "Деньги"
                case "counters": return "Счётные слова"
                case "greetings": return "Приветствия"
                default: return val
                }

            case "pos":
                switch val {
                case "verb": return "Глаголы"
                case "noun": return "Существительные"
                case "adjective": return "Прилагательные"
                default: return val
                }

            case "list":
                switch val {
                case "top100": return "Топ 100"
                case "top500": return "Топ 500"
                default: return val
                }

            default:
                return tag
            }
        }
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
