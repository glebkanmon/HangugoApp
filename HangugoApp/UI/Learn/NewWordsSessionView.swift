import SwiftUI

struct NewWordsSessionView: View {
    @AppStorage("newWordsPerSession") private var newWordsPerSession: Int = 10
    @AppStorage("firstReviewTomorrow") private var firstReviewTomorrow: Bool = true

    let words: [Word]

    @StateObject private var vm = NewWordsSessionViewModel()
    @State private var isAnswerShown: Bool = false

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
                    Text("Можно перейти в повторение или практику предложений.")
                        .foregroundStyle(.secondary)
                }
            } else if vm.isFinished {
                Section {
                    Text("Сессия завершена ✅")
                        .font(.headline)
                    Text("Слова добавлены в повторение.")
                        .foregroundStyle(.secondary)
                }
            } else if let item = vm.currentItem {
                Section("Слово") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(item.word.korean)
                            .font(.system(size: 34, weight: .semibold))

                        // ЕДИНЫЙ блок "ответ" (перевод + картинка), скрываем/раскрываем вместе
                        revealableAnswerBlock(
                            isRevealed: isAnswerShown,
                            hint: "Нажми, чтобы показать перевод и картинку",
                            hasImage: item.word.imageAssetName != nil
                        ) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(item.word.translation)
                                    .foregroundStyle(.secondary)

                                if let imageName = item.word.imageAssetName {
                                    Image(imageName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                        } onReveal: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isAnswerShown = true
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }

                if let example = item.word.example, !example.isEmpty {
                    Section("Пример") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(example)

                            if let exTr = item.word.exampleTranslation, !exTr.isEmpty {
                                Text(exTr)
                                    .foregroundStyle(.secondary)
                                    .blur(radius: isAnswerShown ? 0 : 12)
                                    .redacted(reason: isAnswerShown ? [] : .placeholder)
                                    .opacity(isAnswerShown ? 1 : 0.95)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if !isAnswerShown {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                isAnswerShown = true
                                            }
                                        }
                                    }
                            }
                        }
                    }
                }

                Section {
                    switch item.state {
                    case .fresh:
                        Button {
                            isAnswerShown = false
                            vm.markAlreadyKnown()
                        } label: {
                            Text("Уже знаю")
                                .fontWeight(.semibold)
                        }

                        Button {
                            isAnswerShown = false
                            vm.startLearning()
                        } label: {
                            Text("Начать учить")
                                .fontWeight(.semibold)
                        }

                    case .learning:
                        Button {
                            isAnswerShown = false
                            vm.showLater()
                        } label: {
                            Text("Показать ещё")
                                .fontWeight(.semibold)
                        }

                        Button {
                            isAnswerShown = false
                            vm.markMastered()
                        } label: {
                            Text("Запомнил(а)")
                                .fontWeight(.semibold)
                        }
                    }
                }
            } else {
                Section {
                    Text("Загружаем…")
                        .foregroundStyle(.secondary)
                }
            }
        }
        // ✅ Надёжный iOS 16 фикс: при смене слова List пересоздаётся -> скролл наверх
        .id(vm.currentItem?.id ?? "no_word")
        .onChange(of: vm.currentItem?.id) { _ in
            isAnswerShown = false
        }
        .navigationTitle("Новые слова")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if vm.goal == 0 && vm.masteredCount == 0 && vm.queue.isEmpty && vm.errorMessage == nil {
                isAnswerShown = false
                vm.start(words: words, sessionSize: newWordsPerSession, firstReviewTomorrow: firstReviewTomorrow)
            }
        }
    }

    // MARK: - Helper: revealable answer block (single hint for translation + image)
    @ViewBuilder
    private func revealableAnswerBlock<Content: View>(
        isRevealed: Bool,
        hint: String,
        hasImage: Bool,
        @ViewBuilder content: () -> Content,
        onReveal: @escaping () -> Void
    ) -> some View {
        ZStack {
            content()
                .blur(radius: isRevealed ? 0 : 12)
                .redacted(reason: isRevealed ? [] : .placeholder)
                .opacity(isRevealed ? 1 : 0.95)

            HStack(spacing: 8) {
                Image(systemName: "hand.tap")
                    .foregroundStyle(.secondary)
                Text(hasImage ? hint : "Нажми, чтобы показать перевод")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .opacity(isRevealed ? 0 : 1)
            .allowsHitTesting(false)
            .accessibilityHidden(isRevealed)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isRevealed {
                onReveal()
            }
        }
        .accessibilityAddTraits(.isButton)
    }
}
