// UI/Learn/LearnViewModel.swift

import Foundation
import Combine

@MainActor
final class LearnViewModel: ObservableObject {
    @Published var words: [Word] = []
    @Published var errorMessage: String?

    @Published private(set) var wordsForLearning: [Word] = []
    @Published private(set) var newWordsAvailable: Int = 0
    @Published private(set) var dueToday: Int = 0
    @Published private(set) var categoriesSummary: String = L10n.Learn.categoriesAll

    private let wordsLoader: WordsLoading
    private let srs: SRSService
    private let known: KnownWordsService
    private let selectedTags: SelectedTagsService

    init(
        wordsLoader: WordsLoading,
        srs: SRSService,
        known: KnownWordsService,
        selectedTags: SelectedTagsService
    ) {
        self.wordsLoader = wordsLoader
        self.srs = srs
        self.known = known
        self.selectedTags = selectedTags
    }

    func load() async {
        do {
            // 1) слова
            words = try await wordsLoader.loadWords()

            // 2) SRS
            try srs.load()
            let srsIds = Set(srs.allWordIds())

            // 3) Known
            try known.load()
            let knownIds = Set(known.allWordIds())

            // 4) Selected tags
            try selectedTags.load()
            wordsForLearning = filter(words: words, by: selectedTags.tags)
            categoriesSummary = summary(for: selectedTags.tags)

            // 5) новые
            newWordsAvailable = wordsForLearning.filter { !srsIds.contains($0.id) && !knownIds.contains($0.id) }.count

            // 6) due сегодня
            dueToday = srs.dueItems().count

            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            words = []
            wordsForLearning = []
            newWordsAvailable = 0
            dueToday = 0
            categoriesSummary = L10n.Learn.categoriesAll
        }
    }

    // MARK: - Filtering

    private func filter(words: [Word], by selected: Set<String>) -> [Word] {
        // Семантика:
        // - Внутри namespace — OR
        // - Между namespace — AND
        // - Если в namespace ничего не выбрано — фильтр по нему не применяется
        let selectedTopics = selected.filter { $0.hasPrefix("topic:") }
        let selectedPos = selected.filter { $0.hasPrefix("pos:") }
        let selectedLists = selected.filter { $0.hasPrefix("list:") }

        return words.filter { w in
            let tags = Set(w.tags ?? [])

            if !selectedTopics.isEmpty && tags.isDisjoint(with: selectedTopics) { return false }
            if !selectedPos.isEmpty && tags.isDisjoint(with: selectedPos) { return false }
            if !selectedLists.isEmpty && tags.isDisjoint(with: selectedLists) { return false }

            return true
        }
    }

    private func summary(for selected: Set<String>) -> String {
        // Для Learn на главном экране показываем коротко:
        // если вообще ничего не выбрано — "Все"
        // иначе — "Выбрано: N" (общее кол-во тегов)
        let count = selected.count
        if count == 0 { return L10n.Learn.categoriesAll }
        return String(format: L10n.Learn.categoriesSelectedFormat, count)
    }
}
