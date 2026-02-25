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
                    WordCardHeaderView(
                        korean: word.korean,
                        transcriptionRR: word.transcriptionRR
                    ) {
                        speech.speakKorean(word.korean)
                    }

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
                .padding(.vertical, 2)
            }

            Section(L10n.Common.exampleSection) {
                if let example = normalized(word.example) {
                    ExampleBlockView(
                        example: example,
                        exampleTranslation: word.exampleTranslation,
                        isRevealed: .constant(true) // в деталке всегда видно
                    ) {
                        speech.speakKorean(example)
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

    private func normalized(_ s: String?) -> String? {
        guard let s = s?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        return s
    }
}
