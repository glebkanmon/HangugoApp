// UI/Learn/NewWordsSessionView.swift

import SwiftUI

struct NewWordsSessionView: View {
    @AppStorage("newWordsPerSession") private var newWordsPerSession: Int = 10
    @AppStorage("firstReviewTomorrow") private var firstReviewTomorrow: Bool = true

    private let container: AppContainer
    let words: [Word]

    @StateObject private var vm: NewWordsSessionViewModel
    @State private var isAnswerShown: Bool = false

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
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.word.korean)
                                    .font(.system(size: 34, weight: .semibold))

                                if let rr = normalizedRR(item.word.transcriptionRR) {
                                    Text(rr)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Button {
                                speech.speakKorean(item.word.korean)
                            } label: {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundStyle(.primary)
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Произнести слово")
                        }

                        revealableAnswerBlock(
                            isRevealed: isAnswerShown,
                            hint: L10n.Common.hintTapToRevealAll,
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
                    Section(L10n.Common.exampleSection) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text(example)

                                Spacer()

                                Button {
                                    speech.speakKorean(example)
                                } label: {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .foregroundStyle(.primary)
                                }
                                .buttonStyle(.borderless)
                                .accessibilityLabel("Произнести пример")
                            }

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
                            Text(L10n.NewWordsSession.btnAlreadyKnow)
                                .fontWeight(.semibold)
                        }

                        Button {
                            isAnswerShown = false
                            vm.startLearning()
                        } label: {
                            Text(L10n.NewWordsSession.btnStartLearning)
                                .fontWeight(.semibold)
                        }

                    case .learning:
                        Button {
                            isAnswerShown = false
                            vm.showLater()
                        } label: {
                            Text(L10n.NewWordsSession.btnShowLater)
                                .fontWeight(.semibold)
                        }

                        Button {
                            isAnswerShown = false
                            vm.markMastered()
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
            isAnswerShown = false
        }
        .navigationTitle(L10n.NewWordsSession.navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if vm.goal == 0 && vm.masteredCount == 0 && vm.queue.isEmpty && vm.errorMessage == nil {
                isAnswerShown = false
                vm.start(words: words, sessionSize: newWordsPerSession, firstReviewTomorrow: firstReviewTomorrow)
            }
        }
    }

    private func normalizedRR(_ rr: String?) -> String? {
        guard let rr = rr?.trimmingCharacters(in: .whitespacesAndNewlines), !rr.isEmpty else { return nil }
        return rr
    }

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
                Text(hasImage ? hint : L10n.Common.hintTapToRevealTranslation)
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
            if !isRevealed { onReveal() }
        }
        .accessibilityAddTraits(.isButton)
    }
}
