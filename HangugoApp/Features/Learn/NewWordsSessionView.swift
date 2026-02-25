import SwiftUI

struct NewWordsSessionView: View {
    @AppStorage("newWordsPerSession") private var newWordsPerSession: Int = 10
    @AppStorage("firstReviewTomorrow") private var firstReviewTomorrow: Bool = true

    private let container: AppContainer
    let words: [Word]

    @StateObject private var vm: NewWordsSessionViewModel
    @State private var isRevealed: Bool = false

    private let speech: SpeechService

    init(container: AppContainer, words: [Word]) {
        self.container = container
        self.words = words

        let srs = container.makeSRSService()
        let known = container.makeKnownWordsService()
        _vm = StateObject(wrappedValue: NewWordsSessionViewModel(srs: srs, known: known))
        self.speech = container.speechService
    }

    var body: some View {
        List {
            SessionProgressSectionView(
                progress: vm.progress,
                labelText: "\(L10n.NewWordsSession.progressPrefix) \(vm.masteredCount) / \(vm.goal)",
                accessibilityText: "\(L10n.NewWordsSession.progressPrefix) \(vm.masteredCount) из \(vm.goal)"
            )

            if let error = vm.errorMessage {
                Section(L10n.NewWordsSession.errorSection) {
                    Text(error).foregroundStyle(.secondary)
                }
            }

            if vm.goal == 0 {
                SessionDoneSectionView(
                    title: L10n.NewWordsSession.noNewWordsTitle,
                    subtitle: L10n.NewWordsSession.noNewWordsSubtitle
                )
            } else if vm.isFinished {
                SessionDoneSectionView(
                    title: L10n.NewWordsSession.finishedTitle,
                    subtitle: L10n.NewWordsSession.finishedSubtitle
                )
            } else if let item = vm.currentItem {
                WordPromptSectionView(
                    word: item.word,
                    isRevealed: $isRevealed,
                    speech: speech,
                    revealAccessibilityLabel: "Показать перевод"
                )

                if let example = item.word.example?.normalizedNonEmpty {
                    Section(L10n.Common.exampleSection) {
                        ExampleBlockView(
                            example: example,
                            exampleTranslation: item.word.exampleTranslation,
                            isRevealed: $isRevealed
                        ) {
                            speech.speakKorean(example)
                        }
                    }
                }

                SessionButtonSectionView(actions: actions(for: item))
            } else {
                Section {
                    Text(L10n.NewWordsSession.loading)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .id(vm.currentItem?.id ?? "no_word")
        .onChange(of: vm.currentItem?.id) { _ in
            isRevealed = false
        }
        .navigationTitle(L10n.NewWordsSession.navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if vm.goal == 0 && vm.masteredCount == 0 && vm.queue.isEmpty && vm.errorMessage == nil {
                isRevealed = false
                vm.start(words: words, sessionSize: newWordsPerSession, firstReviewTomorrow: firstReviewTomorrow)
            }
        }
    }

    private func resetRevealAndPerform(_ action: () -> Void) {
        isRevealed = false
        action()
    }

    private func actions(for item: NewWordsSessionViewModel.SessionWord) -> [SessionButtonAction] {
        switch item.state {
        case .fresh:
            return [
                SessionButtonAction(title: L10n.NewWordsSession.btnAlreadyKnow) {
                    resetRevealAndPerform { vm.markAlreadyKnown() }
                },
                SessionButtonAction(title: L10n.NewWordsSession.btnStartLearning) {
                    resetRevealAndPerform { vm.startLearning() }
                }
            ]

        case .learning:
            return [
                SessionButtonAction(title: L10n.NewWordsSession.btnShowLater) {
                    resetRevealAndPerform { vm.showLater() }
                },
                SessionButtonAction(title: L10n.NewWordsSession.btnMastered) {
                    resetRevealAndPerform { vm.markMastered() }
                }
            ]
        }
    }
}
