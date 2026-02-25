import Foundation
import Combine

@MainActor
final class ReviewViewModel: ObservableObject {

    @Published private(set) var dueCount: Int = 0
    @Published private(set) var currentWord: Word?
    @Published var errorMessage: String?

    private let wordsLoader: WordsLoading
    private let srs: SRSService
    private var wordsById: [String: Word] = [:]

    init(wordsLoader: WordsLoading, srs: SRSService) {
        self.wordsLoader = wordsLoader
        self.srs = srs
    }

    func load() {
        do {
            let words = try wordsLoader.loadWords()
            wordsById = Dictionary(uniqueKeysWithValues: words.map { ($0.id, $0) })

            try srs.load()

            let due = srs.dueItems()
            dueCount = due.count
            currentWord = due.first.flatMap { wordsById[$0.wordId] }

        } catch {
            errorMessage = error.localizedDescription
            dueCount = 0
            currentWord = nil
        }
    }

    func rateCurrent(_ rating: ReviewRating) {
        guard let word = currentWord else { return }

        do {
            srs.applySM2(wordId: word.id, rating: rating)
            try srs.persist()

            let due = srs.dueItems()
            dueCount = due.count
            currentWord = due.first.flatMap { wordsById[$0.wordId] }

        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
