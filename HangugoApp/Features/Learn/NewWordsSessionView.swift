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
            Section {
                ProgressView(value: vm.progress)
                HStack {
                    Text("\(L10n.NewWordsSession.progressPrefix) \(vm.masteredCount) / \(vm.goal)")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }

            if let error = vm.errorMessage {
                Section(L10n.NewWordsSession.errorSection) {
                    Text(error)
                        .foregroundStyle(.secondary)
                }
            }

            if vm.goal == 0 {
                Section {
                    Text(L10n.NewWordsSession.noNewWordsTitle)
                        .font(.headline)
                    Text(L10n.NewWordsSession.noNewWordsSubtitle)
                        .foregroundStyle(.secondary)
                }
            } else if vm.isFinished {
                Section {
                    Text(L10n.NewWordsSession.finishedTitle)
                        .font(.headline)
                    Text(L10n.NewWordsSession.finishedSubtitle)
                        .foregroundStyle(.secondary)
                }
            } else if let item = vm.currentItem {
                Section(L10n.Common.wordSection) {
                    VStack(alignment: .leading, spacing: 10) {
                        WordCardHeaderView(
                            korean: item.word.korean,
                            transcriptionRR: item.word.transcriptionRR
                        ) {
                            speech.speakKorean(item.word.korean)
                        }

                        RevealableContent(
                            isRevealed: $isRevealed,
                            hintText: hintText(hasImage: item.word.imageAssetName != nil),
                            accessibilityLabel: "Показать перевод"
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
                        }
                    }
                    .padding(.vertical, 2)
                }

                if let example = normalized(item.word.example) {
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

                Section {
                    switch item.state {
                    case .fresh:
                        Button {
                            resetRevealAndPerform {
                                vm.markAlreadyKnown()
                            }
                        } label: {
                            Text(L10n.NewWordsSession.btnAlreadyKnow)
                                .fontWeight(.semibold)
                        }

                        Button {
                            resetRevealAndPerform {
                                vm.startLearning()
                            }
                        } label: {
                            Text(L10n.NewWordsSession.btnStartLearning)
                                .fontWeight(.semibold)
                        }

                    case .learning:
                        Button {
                            resetRevealAndPerform {
                                vm.showLater()
                            }
                        } label: {
                            Text(L10n.NewWordsSession.btnShowLater)
                                .fontWeight(.semibold)
                        }

                        Button {
                            resetRevealAndPerform {
                                vm.markMastered()
                            }
                        } label: {
                            Text(L10n.NewWordsSession.btnMastered)
                                .fontWeight(.semibold)
                        }
                    }
                }
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

    private func normalized(_ s: String?) -> String? {
        guard let s = s?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        return s
    }

    private func hintText(hasImage: Bool) -> String {
        hasImage ? L10n.Common.hintTapToRevealAll : L10n.Common.hintTapToRevealTranslation
    }
}
