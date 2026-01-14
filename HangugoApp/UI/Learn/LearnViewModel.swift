import Foundation
import Combine

@MainActor
final class LearnViewModel: ObservableObject {
    @Published var words: [Word] = []
    @Published var errorMessage: String?

    @Published private(set) var newWordsAvailable: Int = 0
    @Published private(set) var dueToday: Int = 0

    private let srs = SRSService(store: FileSRSStore())

    func load() {
        do {
            // 1) слова
            words = try BundledWordsLoader.loadWords()

            // 2) SRS
            try srs.load()

            // 3) X: слова, которых нет в SRS
            let srsIds = Set(srs.allWordIds())
            newWordsAvailable = words.filter { !srsIds.contains($0.id) }.count

            // 4) Y: due сегодня
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
