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
            SessionProgressSectionView(
                progress: vm.progress,
                labelText: "\(L10n.Review.progressPrefix) \(vm.completedCount) / \(vm.totalCount)",
                accessibilityText: "\(L10n.Review.progressPrefix) \(vm.completedCount) из \(vm.totalCount)"
            )

            if let error = vm.errorMessage {
                Section {
                    Text(error).foregroundStyle(.secondary)
                }
            } else if vm.dueCount == 0 {
                SessionDoneSectionView(
                    title: L10n.Review.doneTitle,
                    subtitle: L10n.Review.doneSubtitle,
                    actionTitle: L10n.Review.goToPractice,
                    destination: AnyView(PracticeView(container: container))
                )
            } else if let word = vm.currentWord {
                WordPromptSectionView(
                    word: word,
                    isRevealed: $isRevealed,
                    speech: speech,
                    revealAccessibilityLabel: "Показать перевод"
                )

                if let example = word.example?.normalizedNonEmpty {
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

                SessionButtonSectionView(actions: [
                    SessionButtonAction(title: "Вспомнил") {
                        vm.remembered()
                        isRevealed = false
                    },
                    SessionButtonAction(title: "Показать ещё") {
                        vm.showLater()
                        isRevealed = false
                    }
                ])
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
        .task {
            await vm.load()
            isRevealed = false
        }
    }
}
