import Foundation
import Combine

@MainActor
final class NewWordsSessionViewModel: ObservableObject {

    enum SessionState: Equatable {
        case fresh
        case learning
    }

    private enum Phase: Equatable {
        case selecting
        case practicing
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
    private var targetQueueSize: Int = 0

    // MARK: - Internal
    private var remainingNewWords: [Word] = []
    private var phase: Phase = .selecting
    private var learningWordIds: Set<String> = []

    private var q = SessionQueue<SessionWord>(id: { $0.id }) {
        didSet { queue = q.items } // ✅ UI всегда видит актуальный массив
    }

    init(
        srs: SRSService,
        known: KnownWordsService,
        nearEndShuffleWindow: Int = 3
    ) {
        self.srs = srs
        self.known = known
        self.nearEndShuffleWindow = max(1, nearEndShuffleWindow)
    }

    // MARK: - Computed
    var currentItem: SessionWord? { q.current }
    var currentWord: Word? { q.current?.word }

    var isFinished: Bool { goal > 0 && masteredCount >= goal }

    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(1.0, Double(masteredCount) / Double(goal))
    }

    private var learningCount: Int { learningWordIds.count }

    // MARK: - Start
    func start(words: [Word], sessionSize: Int, firstReviewTomorrow: Bool) {
        self.firstReviewTomorrow = firstReviewTomorrow

        do {
            try srs.load()
            try known.load()

            learningWordIds = []
            phase = .selecting

            let srsIds = Set(srs.allWordIds())
            let knownIds = Set(known.allWordIds())

            var newWords = words.filter { !srsIds.contains($0.id) && !knownIds.contains($0.id) }
            newWords.shuffle()

            let size = max(0, sessionSize)
            goal = min(size, newWords.count)
            masteredCount = 0
            errorMessage = nil

            guard goal > 0 else {
                q.setItems([])
                remainingNewWords = []
                targetQueueSize = 0
                return
            }

            targetQueueSize = min(goal, 5)

            let initial = Array(newWords.prefix(targetQueueSize))
            q.setItems(initial.map { SessionWord(word: $0, state: .fresh) })

            remainingNewWords = Array(newWords.dropFirst(targetQueueSize))

        } catch {
            errorMessage = error.localizedDescription
            q.setItems([])
            remainingNewWords = []
            goal = 0
            masteredCount = 0
            targetQueueSize = 0
            learningWordIds = []
            phase = .selecting
        }
    }

    // MARK: - Fresh actions
    func markAlreadyKnown() {
        guard let item = q.current else { return }

        do {
            _ = q.popCurrent()

            known.addKnown(wordId: item.word.id)
            try known.persist()

            if phase == .selecting {
                refillFreshIfNeeded()

                if remainingNewWords.isEmpty,
                   q.items.allSatisfy({ $0.state == .learning }),
                   learningCount < goal {
                    goal = learningCount
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startLearning() {
        guard !q.isEmpty else { return }

        // обновляем state у текущего
        var items = q.items
        let id = items[0].word.id
        items[0].state = .learning
        q.setItems(items)

        learningWordIds.insert(id)

        showLater()

        if phase == .selecting, learningCount >= goal {
            enterPracticePhase()
        }
    }

    // MARK: - Learning actions
    func showLater() {
        q.moveCurrentNearEnd(window: nearEndShuffleWindow)
    }

    func markMastered() {
        guard let item = q.current else { return }

        do {
            _ = q.popCurrent()

            srs.addNewWordToSRS(wordId: item.word.id, firstReviewTomorrow: firstReviewTomorrow)
            try srs.persist()

            masteredCount += 1
            learningWordIds.remove(item.word.id)

            if masteredCount >= goal {
                q.setItems([])
                remainingNewWords = []
                return
            }

            if phase == .selecting {
                if learningCount < goal {
                    refillFreshIfNeeded()

                    if remainingNewWords.isEmpty,
                       q.items.allSatisfy({ $0.state == .learning }),
                       learningCount < goal {
                        goal = learningCount
                    }
                } else {
                    enterPracticePhase()
                }
            } else {
                if q.isEmpty {
                    goal = masteredCount
                }
            }

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Backward compatible aliases
    func markNotYet() { showLater() }
    func markKnown() { markMastered() }

    // MARK: - Private
    private func refillFreshIfNeeded() {
        guard phase == .selecting else { return }
        guard learningCount < goal else {
            enterPracticePhase()
            return
        }

        var items = q.items

        while items.count < targetQueueSize,
              !remainingNewWords.isEmpty,
              learningCount < goal {
            let next = remainingNewWords.removeFirst()
            items.append(SessionWord(word: next, state: .fresh))
        }

        if items.isEmpty,
           !remainingNewWords.isEmpty,
           learningCount < goal {
            let next = remainingNewWords.removeFirst()
            items.append(SessionWord(word: next, state: .fresh))
        }

        q.setItems(items)
    }

    private func enterPracticePhase() {
        phase = .practicing

        var items = q.items
        items.removeAll { $0.state == .fresh }
        items.shuffle()
        q.setItems(items)
    }
}
