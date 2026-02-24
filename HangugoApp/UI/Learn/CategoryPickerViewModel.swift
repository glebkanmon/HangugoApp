// UI/Learn/CategoryPickerViewModel.swift

import Combine
import Foundation

@MainActor
final class CategoryPickerViewModel: ObservableObject {
    @Published private(set) var allTags: Set<String> = []
    @Published var selectedTags: Set<String> = []

    @Published private(set) var topicTags: [String] = []
    @Published private(set) var posTags: [String] = []
    @Published private(set) var listTags: [String] = []

    private let service: SelectedTagsService

    init(words: [Word], service: SelectedTagsService = SelectedTagsService(store: FileSelectedTagsStore())) {
        self.service = service

        let tags = Set(words.flatMap { $0.tags ?? [] })
        self.allTags = tags

        func sortedTags(_ tags: [String]) -> [String] {
            tags.sorted { L10n.Categories.displayName(for: $0).localizedCaseInsensitiveCompare(L10n.Categories.displayName(for: $1)) == .orderedAscending }
        }

        self.topicTags = sortedTags(tags.filter { $0.hasPrefix("topic:") })
        self.posTags = sortedTags(tags.filter { $0.hasPrefix("pos:") })
        self.listTags = sortedTags(tags.filter { $0.hasPrefix("list:") })
    }

    func load() {
        do {
            try service.load()
            selectedTags = service.tags
        } catch {
            selectedTags = []
        }
    }

    func toggle(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
        save()
    }

    func reset() {
        selectedTags = []
        save()
    }

    private func save() {
        do {
            try service.set(selectedTags)
        } catch {
            // MVP: молча, чтобы не раздражать пользователя; позже можно баннер/алерт
        }
    }
}
