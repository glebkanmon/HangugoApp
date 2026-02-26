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

    private var queue = SessionQueue<String>(id: { $0 })
    private var hadShowLater: Set<String> = []

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

    func load() async {
        do {
            let words = try await wordsLoader.loadWords()
            wordsById = Dictionary(uniqueKeysWithValues: words.map { ($0.id, $0) })

            try srs.load()

            let dueIds = srs.dueItems()
                .map { $0.wordId }
                .filter { wordsById[$0] != nil }

            queue.setItems(dueIds)
            hadShowLater = []

            totalCount = dueIds.count
            completedCount = 0
            dueCount = queue.count
            currentWord = queue.current.flatMap { wordsById[$0] }
            errorMessage = nil

        } catch {
            errorMessage = error.localizedDescription
            totalCount = 0
            completedCount = 0
            dueCount = 0
            currentWord = nil
            queue.setItems([])
            hadShowLater = []
        }
    }

    /// "Показать ещё": не трогаем SRS внутри сессии, только очередь + локальный сигнал "трудно".
    func showLater() {
        guard let currentId = queue.currentId(), queue.count > 1 else { return }

        hadShowLater.insert(currentId)
        queue.moveCurrentNearEnd(window: nearEndShuffleWindow)

        dueCount = queue.count
        currentWord = queue.current.flatMap { wordsById[$0] }
    }

    /// "Вспомнил": применяем SM-2 и убираем слово из очереди.
    func remembered() {
        guard let id = queue.currentId() else { return }
        guard wordsById[id] != nil else { return }

        do {
            let rating: ReviewRating = hadShowLater.contains(id) ? .hard : .normal

            srs.applySM2(wordId: id, rating: rating)
            try srs.persist()

            _ = queue.popCurrent()
            hadShowLater.remove(id)

            completedCount += 1
            dueCount = queue.count
            currentWord = queue.current.flatMap { wordsById[$0] }

        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
