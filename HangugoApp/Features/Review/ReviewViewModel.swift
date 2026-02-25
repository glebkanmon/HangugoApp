import Foundation
import Combine

@MainActor
final class ReviewViewModel: ObservableObject {

    @Published private(set) var totalCount: Int = 0
    @Published private(set) var completedCount: Int = 0
    @Published private(set) var dueCount: Int = 0
    @Published private(set) var currentWord: Word?
    @Published var errorMessage: String?

    private let wordsLoader: WordsLoading
    private let srs: SRSService
    private var wordsById: [String: Word] = [:]

    private let nearEndShuffleWindow: Int
    private var queue: [String] = []                // wordIds
    private var hadShowLater: Set<String> = []      // local difficulty signal

    init(
        wordsLoader: WordsLoading,
        srs: SRSService,
        nearEndShuffleWindow: Int = 3
    ) {
        self.wordsLoader = wordsLoader
        self.srs = srs
        self.nearEndShuffleWindow = max(1, nearEndShuffleWindow)
    }

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return min(1.0, Double(completedCount) / Double(totalCount))
    }

    func load() {
        do {
            let words = try wordsLoader.loadWords()
            wordsById = Dictionary(uniqueKeysWithValues: words.map { ($0.id, $0) })

            try srs.load()

            // Берём due на этот момент и фиксируем очередь на всю сессию.
            // Фильтруем те, которых нет в wordsById (на случай рассинхрона данных).
            let dueIds = srs.dueItems()
                .map { $0.wordId }
                .filter { wordsById[$0] != nil }

            queue = dueIds
            hadShowLater = []

            totalCount = dueIds.count
            completedCount = 0
            dueCount = queue.count
            currentWord = queue.first.flatMap { wordsById[$0] }
            errorMessage = nil

        } catch {
            errorMessage = error.localizedDescription
            totalCount = 0
            completedCount = 0
            dueCount = 0
            currentWord = nil
            queue = []
            hadShowLater = []
        }
    }

    /// "Показать ещё" — НЕ трогаем SRS (чтобы не ломать текущую очередь),
    /// просто запоминаем, что слово было трудным, и перемещаем ближе к концу.
    func showLater() {
        guard queue.count > 1 else { return }
        let id = queue.removeFirst()
        hadShowLater.insert(id)

        let n = queue.count
        let window = min(nearEndShuffleWindow, n)
        let startIndex = max(0, n - window)
        let insertIndex = Int.random(in: startIndex...n) // n == append
        queue.insert(id, at: insertIndex)

        dueCount = queue.count
        currentWord = queue.first.flatMap { wordsById[$0] }
    }

    /// "Вспомнил" — применяем SM-2 и убираем слово из очереди.
    /// Если слово ранее было "Показать ещё", считаем его трудным → .hard, иначе .normal.
    func remembered() {
        guard let id = queue.first else { return }
        guard let _ = wordsById[id] else { return }

        do {
            let rating: ReviewRating = hadShowLater.contains(id) ? .hard : .normal

            srs.applySM2(wordId: id, rating: rating)
            try srs.persist()

            _ = queue.removeFirst()
            hadShowLater.remove(id)

            completedCount += 1
            dueCount = queue.count
            currentWord = queue.first.flatMap { wordsById[$0] }

        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
