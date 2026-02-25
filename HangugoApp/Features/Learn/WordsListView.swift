// UI/Learn/WordsListView.swift

import SwiftUI

struct WordsListView: View {
    private let container: AppContainer
    let words: [Word]

    @State private var searchText: String = ""

    init(container: AppContainer, words: [Word]) {
        self.container = container
        self.words = words
    }

    private var filteredWords: [Word] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return words.sorted { $0.korean.localizedCaseInsensitiveCompare($1.korean) == .orderedAscending }
        }

        return words
            .filter { word in
                word.korean.localizedCaseInsensitiveContains(query) ||
                word.translation.localizedCaseInsensitiveContains(query) ||
                (word.example?.localizedCaseInsensitiveContains(query) ?? false) ||
                (word.exampleTranslation?.localizedCaseInsensitiveContains(query) ?? false)
            }
            .sorted { $0.korean.localizedCaseInsensitiveCompare($1.korean) == .orderedAscending }
    }

    var body: some View {
        List {
            if filteredWords.isEmpty {
                Section {
                    Text(L10n.Words.empty)
                        .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    ForEach(filteredWords) { word in
                        NavigationLink {
                            WordDetailView(container: container, word: word)
                        } label: {
                            WordRow(word: word)
                        }
                    }
                }
            }
        }
        .navigationTitle(L10n.Words.navTitleAllWords)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: L10n.Words.searchPlaceholder)
    }
}

#Preview {
    NavigationStack {
        WordsListView(container: AppContainer(), words: [])
    }
}
