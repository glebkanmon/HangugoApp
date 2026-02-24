import Foundation
import Combine

@MainActor
final class NewWordsSessionViewModel: ObservableObject {

    // MARK: - Types
    enum SessionState: Equatable {
        case fresh     // ещё не приняли решение (первый показ)
        case learning  // выбрали "Начать учить"
    }

    private enum Phase: Equatable {
        case selecting     // набираем goal слов через "Начать учить"
        case practicing    // крутим только learning-слова до "Запомнил(а)" на всех
    }

    struct SessionWord: Identifiable, Equatable {
        let id: String
        let word: Word
        var state: SessionState

        init(word: Word, state: SessionState) {
            self.id = word.id
            self.word = word
            self.state = state
        }
    }

    // MARK: - Published state
    @Published private(set) var queue: [SessionWord] = []
    @Published private(set) var goal: Int = 0
    @Published private(set) var masteredCount: Int = 0
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let srs: SRSService
    private let known: KnownWordsService

    // MARK: - Config
    private let nearEndShuffleWindow: Int
    private var firstReviewTomorrow: Bool = true

    /// Сколько элементов держим одновременно в очереди на этапе выбора.
    private var targetQueueSize: Int = 0

    // MARK: - Private state
    private var remainingNewWords: [Word] = []
    private var phase: Phase = .selecting

    /// Набор слов, для которых нажали "Начать учить"
    private var learningWordIds: Set<String> = []

    init(
        srs: SRSService = SRSService(store: FileSRSStore()),
        known: KnownWordsService = KnownWordsService(store: FileKnownWordsStore()),
        nearEndShuffleWindow: Int = 3,
        firstReviewTomorrow: Bool = true
    ) {
        self.srs = srs
        self.known = known
        self.nearEndShuffleWindow = max(1, nearEndShuffleWindow)
        self.firstReviewTomorrow = firstReviewTomorrow
    }

    // MARK: - Computed
    var currentItem: SessionWord? { queue.first }
    var currentWord: Word? { queue.first?.word }

    var isFinished: Bool { goal > 0 && masteredCount >= goal }

    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(1.0, Double(masteredCount) / Double(goal))
    }

    private var learningCount: Int { learningWordIds.count }

    // MARK: - Session start
    func start(words: [Word], sessionSize: Int, firstReviewTomorrow: Bool) {
        self.firstReviewTomorrow = firstReviewTomorrow

        do {
            try srs.load()
            try known.load()

            learningWordIds = []
            phase = .selecting

            let srsIds = Set(srs.allWordIds())
            let knownIds = Set(known.allWordIds())

            // Новые слова = не в SRS и не в Known
            var newWords = words.filter { !srsIds.contains($0.id) && !knownIds.contains($0.id) }
            newWords.shuffle()

            let size = max(0, sessionSize)
            goal = min(size, newWords.count)
            masteredCount = 0
            errorMessage = nil

            guard goal > 0 else {
                queue = []
                remainingNewWords = []
                targetQueueSize = 0
                return
            }

            // На этапе выбора держим небольшой пул
            targetQueueSize = min(goal, 5)

            let initial = Array(newWords.prefix(targetQueueSize))
            queue = initial.map { SessionWord(word: $0, state: .fresh) }

            remainingNewWords = Array(newWords.dropFirst(targetQueueSize))
        } catch {
            errorMessage = error.localizedDescription
            queue = []
            remainingNewWords = []
            goal = 0
            masteredCount = 0
            targetQueueSize = 0
            learningWordIds = []
            phase = .selecting
        }
    }

    // MARK: - Actions (Fresh)
    /// "Уже знаю" — помечаем Known, заменяем на другое новое слово
    /// Важно: заменяем только пока не набрали learningCount == goal.
    func markAlreadyKnown() {
        guard let item = queue.first else { return }

        do {
            _ = queue.removeFirst()

            known.addKnown(wordId: item.word.id)
            try known.persist()

            if phase == .selecting {
                refillFreshIfNeeded()

                // Если новых слов больше нет и набрать цель нельзя — корректируем goal по факту
                if remainingNewWords.isEmpty,
                   queue.allSatisfy({ $0.state == .learning }),
                   learningCount < goal {
                    goal = learningCount
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// "Начать учить" — переводим слово в learning и дальше оно участвует в круге
    /// Как только learningCount достигнет goal → переходим в фазу practising (никаких новых слов).
    func startLearning() {
        guard !queue.isEmpty else { return }

        let id = queue[0].word.id
        queue[0].state = .learning
        learningWordIds.insert(id)

        showLater()

        if phase == .selecting, learningCount >= goal {
            enterPracticePhase()
        }
    }

    // MARK: - Actions (Learning)
    /// "Показать ещё" — перемещаем ближе к концу
    func showLater() {
        guard !queue.isEmpty else { return }

        let item = queue.removeFirst()
        if queue.isEmpty {
            queue.append(item)
            return
        }

        let n = queue.count
        let window = min(nearEndShuffleWindow, n)
        let startIndex = max(0, n - window)
        let insertIndex = Int.random(in: startIndex...n) // n == append
        queue.insert(item, at: insertIndex)
    }

    /// "Запомнил(а)" — добавляем в SRS и убираем из круга.
    /// В фазе practicing — новых слов не добавляем вообще.
    func markMastered() {
        guard let item = queue.first else { return }

        do {
            _ = queue.removeFirst()

            srs.addNewWordToSRS(wordId: item.word.id, firstReviewTomorrow: firstReviewTomorrow)
            try srs.persist()

            masteredCount += 1
            learningWordIds.remove(item.word.id)

            if masteredCount >= goal {
                queue = []
                remainingNewWords = []
                return
            }

            // Если ещё выбираем learning-слова и их пока меньше цели — можно добрать свежие
            if phase == .selecting {
                if learningCount < goal {
                    refillFreshIfNeeded()

                    // Если добрать невозможно — корректируем goal
                    if remainingNewWords.isEmpty,
                       queue.allSatisfy({ $0.state == .learning }),
                       learningCount < goal {
                        goal = learningCount
                    }
                } else {
                    enterPracticePhase()
                }
            } else {
                // practicing: ничего не добавляем, просто продолжаем круг по оставшимся learning
                if queue.isEmpty {
                    // теоретически может случиться, если learningCount < goal (не хватило слов)
                    goal = masteredCount
                }
            }

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Backward compatible (старые имена)
    func markNotYet() { showLater() }
    func markKnown() { markMastered() }

    // MARK: - Private helpers

    /// Добавляем свежие слова только на этапе выбора и только пока learningCount < goal.
    private func refillFreshIfNeeded() {
        guard phase == .selecting else { return }
        guard learningCount < goal else {
            enterPracticePhase()
            return
        }

        while queue.count < targetQueueSize,
              !remainingNewWords.isEmpty,
              learningCount < goal {
            let next = remainingNewWords.removeFirst()
            queue.append(SessionWord(word: next, state: .fresh))
        }

        if queue.isEmpty, let _ = remainingNewWords.first, learningCount < goal {
            let next = remainingNewWords.removeFirst()
            queue.append(SessionWord(word: next, state: .fresh))
        }
    }

    /// Переход в режим "крутим только выбранные learning-слова"
    private func enterPracticePhase() {
        phase = .practicing

        // Убираем все свежие слова (по ним уже не принимаем решение)
        queue.removeAll { $0.state == .fresh }

        // Перемешаем, чтобы не было ощущения "всегда одно и то же"
        queue.shuffle()
    }
}
