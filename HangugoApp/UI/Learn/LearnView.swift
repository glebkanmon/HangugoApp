// UI/Learn/LearnView.swift

import SwiftUI

struct LearnView: View {
    private let container: AppContainer
    @StateObject private var vm: LearnViewModel

    init(container: AppContainer) {
        self.container = container
        _vm = StateObject(
            wrappedValue: LearnViewModel(
                wordsLoader: container.wordsLoader,
                srs: container.makeSRSService(),
                known: container.makeKnownWordsService(),
                selectedTags: container.makeSelectedTagsService()
            )
        )
    }

    var body: some View {
        List {
            // ✅ Фильтры — в самом верху
            Section(L10n.Learn.filtersSection) {
                NavigationLink {
                    CategoryPickerView(container: container, words: vm.words)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundStyle(.primary)

                        Text(L10n.Learn.categories)

                        Spacer()

                        Text(vm.categoriesSummary)
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(vm.words.isEmpty)
            }

            Section(L10n.Learn.sessionsSection) {
                NavigationLink {
                    NewWordsSessionView(container: container, words: vm.wordsForLearning)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.primary)

                        Text(L10n.Learn.newWords)

                        Spacer()

                        Text("\(vm.newWordsAvailable)")
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(vm.newWordsAvailable == 0 || vm.wordsForLearning.isEmpty)

                NavigationLink {
                    ReviewView(container: container)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "clock")
                            .foregroundStyle(.primary)

                        Text(L10n.Learn.reviewToday)

                        Spacer()

                        Text("\(vm.dueToday)")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section(L10n.Learn.hangulSection) {
                Label(L10n.Learn.soonAlphabet, systemImage: "textformat.abc")
                    .foregroundStyle(.primary)

                Label(L10n.Learn.soonSyllables, systemImage: "square.grid.2x2")
                    .foregroundStyle(.primary)

                Label(L10n.Learn.soonReading, systemImage: "book.pages")
                    .foregroundStyle(.primary)
            }

            Section(L10n.Learn.wordsSection) {
                if let error = vm.errorMessage {
                    Text(error).foregroundStyle(.secondary)
                } else if vm.words.isEmpty {
                    Text(L10n.Learn.loading).foregroundStyle(.secondary)
                } else {
                    NavigationLink {
                        WordsListView(container: container, words: vm.words)
                    } label: {
                        Label(L10n.Learn.allWords, systemImage: "list.bullet")
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .navigationTitle(L10n.Learn.navTitle)
        .onAppear { vm.load() }
    }
}

#Preview {
    NavigationStack { LearnView(container: AppContainer()) }
}
