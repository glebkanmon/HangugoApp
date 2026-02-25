import SwiftUI

struct ReviewView: View {
    private let container: AppContainer
    @StateObject private var vm: ReviewViewModel

    @State private var isRevealed: Bool = false
    private let speech: SpeechService

    init(container: AppContainer) {
        self.container = container
        _vm = StateObject(
            wrappedValue: ReviewViewModel(
                wordsLoader: container.wordsLoader,
                srs: container.makeSRSService()
            )
        )
        self.speech = container.speechService
    }

    var body: some View {
        List {
            Section {
                ProgressView(value: vm.progress)

                HStack {
                    Text("Прогресс: \(vm.completedCount) / \(vm.totalCount)")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .accessibilityLabel("Прогресс \(vm.completedCount) из \(vm.totalCount)")
            }

            Section(L10n.Review.todaySection) {
                if let error = vm.errorMessage {
                    Text(error).foregroundStyle(.secondary)
                } else {
                    Text("\(L10n.Review.dueCountPrefix) \(vm.dueCount)")
                }
            }

            if vm.dueCount == 0 {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.Review.doneTitle)
                            .font(.headline)
                        Text(L10n.Review.doneSubtitle)
                            .foregroundStyle(.secondary)

                        NavigationLink(L10n.Review.goToPractice) {
                            PracticeView(container: container)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } else if let word = vm.currentWord {
                Section(L10n.Common.wordSection) {
                    VStack(alignment: .leading, spacing: 10) {
                        WordCardHeaderView(
                            korean: word.korean,
                            transcriptionRR: word.transcriptionRR
                        ) {
                            speech.speakKorean(word.korean)
                        }

                        RevealableContent(
                            isRevealed: $isRevealed,
                            hintText: hintText(hasImage: word.imageAssetName != nil),
                            accessibilityLabel: "Показать перевод"
                        ) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(word.translation)
                                    .foregroundStyle(.secondary)

                                if let imageName = word.imageAssetName {
                                    Image(imageName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.vertical, 2)
                }

                if let example = normalized(word.example) {
                    Section(L10n.Common.exampleSection) {
                        ExampleBlockView(
                            example: example,
                            exampleTranslation: word.exampleTranslation,
                            isRevealed: $isRevealed
                        ) {
                            speech.speakKorean(example)
                        }
                    }
                }

                Section {
                    Button {
                        vm.remembered()
                        isRevealed = false
                    } label: {
                        Text("Вспомнил")
                            .fontWeight(.semibold)
                    }

                    Button {
                        vm.showLater()
                        isRevealed = false
                    } label: {
                        Text("Показать ещё")
                            .fontWeight(.semibold)
                    }
                }
            } else {
                Section {
                    Text(L10n.Review.missingWord)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .id(vm.currentWord?.id ?? "no_word")
        .onChange(of: vm.currentWord?.id) { _ in
            isRevealed = false
        }
        .navigationTitle(L10n.Review.navTitle)
        .onAppear {
            vm.load()
            isRevealed = false
        }
    }

    private func normalized(_ s: String?) -> String? {
        guard let s = s?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        return s
    }

    private func hintText(hasImage: Bool) -> String {
        hasImage ? L10n.Common.hintTapToRevealAll : L10n.Common.hintTapToRevealTranslation
    }
}
