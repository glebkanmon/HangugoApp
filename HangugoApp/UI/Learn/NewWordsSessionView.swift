import SwiftUI

struct NewWordsSessionView: View {
    @AppStorage("newWordsPerSession") private var newWordsPerSession: Int = 10
    @AppStorage("firstReviewTomorrow") private var firstReviewTomorrow: Bool = true
    
    let words: [Word]

    @StateObject private var vm = NewWordsSessionViewModel()

    var body: some View {
        List {
            Section {
                ProgressView(value: vm.progress)
                HStack {
                    Text("Запомнил: \(vm.masteredCount) / \(vm.goal)")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }

            if let error = vm.errorMessage {
                Section("Ошибка") {
                    Text(error)
                        .foregroundStyle(.secondary)
                }
            }

            if vm.goal == 0 {
                Section {
                    Text("Новых слов нет ✅")
                        .font(.headline)
                    Text("Возвращайся в повторение или практику предложений.")
                        .foregroundStyle(.secondary)
                }
            } else if vm.isFinished {
                Section {
                    Text("Сессия завершена ✅")
                        .font(.headline)
                    Text("Слова добавлены в повторение.")
                        .foregroundStyle(.secondary)
                }
            } else if let word = vm.currentWord {
                Section("Слово") {
                    // reuse WordRow, чтобы единый стиль
                    WordRow(word: word)
                }

                if let example = word.example, !example.isEmpty {
                    Section("Пример") {
                        Text(example)
                    }
                }

                Section {
                    Button {
                        vm.markNotYet()
                    } label: {
                        Text("Пока нет")
                    }

                    Button {
                        vm.markKnown()
                    } label: {
                        Text("Запомнил")
                    }
                }
            } else {
                Section {
                    Text("Загружаем…")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Новые слова")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // стартуем сессию один раз
            if vm.goal == 0 && vm.masteredCount == 0 && vm.queue.isEmpty && vm.errorMessage == nil {
                vm.start(words: words, sessionSize: newWordsPerSession, firstReviewTomorrow: firstReviewTomorrow)
            }
        }
    }
}
