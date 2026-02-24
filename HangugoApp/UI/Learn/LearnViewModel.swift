import Foundation
import Combine

@MainActor
final class LearnViewModel: ObservableObject {
    @Published var words: [Word] = []
    @Published var errorMessage: String?

    @Published private(set) var newWordsAvailable: Int = 0
    @Published private(set) var dueToday: Int = 0

    private let srs = SRSService(store: FileSRSStore())
    private let known = KnownWordsService(store: FileKnownWordsStore())

    func load() {
        do {
            // 1) слова
            words = try BundledWordsLoader.loadWords()

            // 2) SRS
            try srs.load()
            let srsIds = Set(srs.allWordIds())

            // 3) Known (уже знаю — не добавляем в SRS, но исключаем из "новых")
            try known.load()
            let knownIds = Set(known.allWordIds())

            // 4) X: новые (не в SRS и не в Known)
            newWordsAvailable = words.filter { !srsIds.contains($0.id) && !knownIds.contains($0.id) }.count

            // 5) Y: due сегодня
            dueToday = srs.dueItems().count

            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            words = []
            newWordsAvailable = 0
            dueToday = 0
        }
    }
}
