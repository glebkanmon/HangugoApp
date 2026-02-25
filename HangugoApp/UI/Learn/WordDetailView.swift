// UI/Learn/WordDetailView.swift

import SwiftUI

struct WordDetailView: View {
    private let container: AppContainer
    let word: Word
    private let speech: SpeechService

    init(container: AppContainer, word: Word) {
        self.container = container
        self.word = word
        self.speech = container.speechService
    }

    var body: some View {
        List {
            Section(L10n.Common.wordSection) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(word.korean)
                                .font(.system(size: 34, weight: .semibold))

                            if let rr = normalizedRR(word.transcriptionRR) {
                                Text(rr)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Text(word.translation)
                                .foregroundStyle(.secondary)
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
                }
                .padding(.vertical, 2)
            }

            Section(L10n.Common.exampleSection) {
                if let example = word.example, !example.isEmpty {
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
                        }
                    }
                } else {
                    Text(L10n.WordDetail.noExample)
                        .foregroundStyle(.secondary)
                }
            }

            Section(L10n.WordDetail.practiceSection) {
                NavigationLink(L10n.WordDetail.tryInPractice) {
                    PracticeView(container: container, word: word)
                }
            }
        }
        .navigationTitle(word.korean)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func normalizedRR(_ rr: String?) -> String? {
        guard let rr = rr?.trimmingCharacters(in: .whitespacesAndNewlines), !rr.isEmpty else { return nil }
        return rr
    }
}
