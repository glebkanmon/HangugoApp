import Foundation
import Combine

@MainActor
final class NewWordsSessionViewModel: ObservableObject {

    // MARK: - Published state
    @Published private(set) var queue: [Word] = []
    @Published private(set) var goal: Int = 0
    @Published private(set) var masteredCount: Int = 0
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let srs: SRSService

    // MARK: - Config
    private let nearEndShuffleWindow: Int
    private var firstReviewTomorrow: Bool = true


    init(
        srs: SRSService = SRSService(store: FileSRSStore()),
        nearEndShuffleWindow: Int = 3,
        firstReviewTomorrow: Bool = true
    ) {
        self.srs = srs
        self.nearEndShuffleWindow = max(1, nearEndShuffleWindow)
        self.firstReviewTomorrow = firstReviewTomorrow
    }

    // MARK: - Computed
    var currentWord: Word? { queue.first }
    var isFinished: Bool { goal > 0 && masteredCount >= goal || (goal > 0 && queue.isEmpty) }

    /// 0...1 для ProgressView(value:)
    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(1.0, Double(masteredCount) / Double(goal))
    }

    // MARK: - Session start
    /// words: все слова из словаря
    /// sessionSize: настройка "N новых слов за сессию"
    func start(words: [Word], sessionSize: Int, firstReviewTomorrow: Bool) {
        self.firstReviewTomorrow = firstReviewTomorrow
        do {
            try srs.load()

            // Новые слова = те, которых ещё нет в SRS
            // (самый надёжный критерий "в изучении/повторении")
            let existingIds = Set(srsAllWordIds())

            let newWords = words.filter { !existingIds.contains($0.id) }

            let size = max(0, sessionSize)
            goal = min(size, newWords.count)
            masteredCount = 0
            errorMessage = nil

            // Берём первые goal слов (позже можно рандом/умный выбор)
            queue = Array(newWords.prefix(goal))
        } catch {
            errorMessage = error.localizedDescription
            queue = []
            goal = 0
            masteredCount = 0
        }
    }

    // MARK: - Actions
    /// Пользователь: "Пока нет"
    func markNotYet() {
        guard !queue.isEmpty else { return }

        // Берём текущее слово и переносим ближе к концу,
        // чтобы оно вернулось позже, но не строго "через одинаковый интервал".
        let word = queue.removeFirst()
        if queue.isEmpty {
            queue.append(word)
            return
        }

        let n = queue.count
        let window = min(nearEndShuffleWindow, n) // диапазон размеров
        let startIndex = max(0, n - window)
        let insertIndex = Int.random(in: startIndex...n) // n == append
        queue.insert(word, at: insertIndex)
    }

    /// Пользователь: "Запомнил"
    func markKnown() {
        guard let word = queue.first else { return }

        do {
            // 1) Убираем из очереди (без индексов — безопасно)
            _ = queue.removeFirst()

            // 2) Добавляем в SRS и сохраняем
            srs.addNewWordToSRS(wordId: word.id, firstReviewTomorrow: firstReviewTomorrow)
            try srs.persist()

            // 3) Прогресс
            masteredCount += 1

            // Если вдруг слово было последним — queue станет пустой, это ок.
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Private helpers
    private func srsAllWordIds() -> [String] {
        // Нет публичного доступа к cached — но нам нужен список IDs.
        // Самый простой MVP-хак: получить из store напрямую.
        // Чтобы не плодить новый store, используем текущий store через load() уже сделан,
        // а вот список IDs можно достать через dueItems + “не due”.
        // Поэтому в MVP проще: загрузить из store ещё раз тут — но мы не хотим.
        //
        // Лучшее MVP-решение: добавить метод в SRSService: allWordIds().
        // Сделаем это ниже.
        return srs.allWordIds()
    }
}
