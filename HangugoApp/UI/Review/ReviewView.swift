// UI/Review/ReviewView.swift

import SwiftUI

struct ReviewView: View {
    @StateObject private var vm = ReviewViewModel()
    @State private var isAnswerRevealed: Bool = false

    private let speech = SpeechService.shared

    var body: some View {
        List {
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
                        Text(L10n.Review.doneTitle).font(.headline)
                        Text(L10n.Review.doneSubtitle).foregroundStyle(.secondary)

                        NavigationLink(L10n.Review.goToPractice) {
                            PracticeView()
                        }
                    }
                    .padding(.vertical, 4)
                }
            } else if let word = vm.currentWord {
                Section(L10n.Common.wordSection) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(word.korean)
                                    .font(.system(size: 34, weight: .semibold))

                                if let rr = normalizedRR(word.transcriptionRR) {
                                    Text(rr)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Button {
                                speech.speakKorean(word.korean)
                            } label: {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundStyle(.primary)
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Произнести слово")
                        }

                        revealableAnswerBlock(
                            isRevealed: isAnswerRevealed,
                            hint: L10n.Common.hintTapToRevealAll,
                            hasImage: word.imageAssetName != nil
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

                        } onReveal: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isAnswerRevealed = true
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }

                if let example = word.example, !example.isEmpty {
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

                            if let exTr = word.exampleTranslation, !exTr.isEmpty {
                                Text(exTr)
                                    .foregroundStyle(.secondary)
                                    .blur(radius: isAnswerRevealed ? 0 : 12)
                                    .redacted(reason: isAnswerRevealed ? [] : .placeholder)
                                    .opacity(isAnswerRevealed ? 1 : 0.95)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if !isAnswerRevealed {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                isAnswerRevealed = true
                                            }
                                        }
                                    }
                            }
                        }
                    }
                }

                Section(L10n.Review.ratingSection) {
                    Button { rateAndAdvance(.hard) } label: {
                        Label(L10n.Review.btnHard, systemImage: "tortoise")
                            .fontWeight(.semibold)
                    }
                    .disabled(!isAnswerRevealed)

                    Button { rateAndAdvance(.normal) } label: {
                        Label(L10n.Review.btnNormal, systemImage: "figure.walk")
                            .fontWeight(.semibold)
                    }
                    .disabled(!isAnswerRevealed)

                    Button { rateAndAdvance(.easy) } label: {
                        Label(L10n.Review.btnEasy, systemImage: "hare")
                            .fontWeight(.semibold)
                    }
                    .disabled(!isAnswerRevealed)
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
            isAnswerRevealed = false
        }
        .navigationTitle(L10n.Review.navTitle)
        .onAppear {
            vm.load()
            isAnswerRevealed = false
        }
    }

    private func normalizedRR(_ rr: String?) -> String? {
        guard let rr = rr?.trimmingCharacters(in: .whitespacesAndNewlines), !rr.isEmpty else { return nil }
        return rr
    }

    private func rateAndAdvance(_ rating: ReviewRating) {
        vm.rateCurrent(rating)
        isAnswerRevealed = false
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
