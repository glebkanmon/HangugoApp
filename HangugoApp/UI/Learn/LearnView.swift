import SwiftUI

struct LearnView: View {
    @StateObject private var vm = LearnViewModel()

    var body: some View {
        List {
            Section("Сессии") {

                NavigationLink {
                    NewWordsSessionView(words: vm.words)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.primary)

                        Text("Новые слова")

                        Spacer()

                        Text("\(vm.newWordsAvailable)")
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(vm.newWordsAvailable == 0 || vm.words.isEmpty)

                NavigationLink {
                    ReviewView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "clock")
                            .foregroundStyle(.primary)

                        Text("Повторить сегодня")

                        Spacer()

                        Text("\(vm.dueToday)")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Хангыль") {
                Label("Алфавит (скоро)", systemImage: "textformat.abc")
                    .foregroundStyle(.primary)

                Label("Слоги (скоро)", systemImage: "square.grid.2x2")
                    .foregroundStyle(.primary)

                Label("Чтение (скоро)", systemImage: "book.pages")
                    .foregroundStyle(.primary)
            }

            Section("Слова") {
                if let error = vm.errorMessage {
                    Text(error).foregroundStyle(.secondary)
                } else if vm.words.isEmpty {
                    Text("Загрузка…").foregroundStyle(.secondary)
                } else {
                    NavigationLink {
                        WordsListView(words: vm.words)
                    } label: {
                        Label("Все слова", systemImage: "list.bullet")
                            .foregroundStyle(.primary)
                    }

                    let first = vm.words[0]
                    NavigationLink {
                        WordDetailView(word: first)
                    } label: {
                        WordRow(word: first)
                    }
                }
            }
        }
        .navigationTitle("Изучение")
        .onAppear { vm.load() }
    }
}

#Preview {
    NavigationStack { LearnView() }
}
