import SwiftUI

struct WordPromptSectionView: View {
    let word: Word
    @Binding var isRevealed: Bool
    let speech: SpeechService
    let revealAccessibilityLabel: String

    init(
        word: Word,
        isRevealed: Binding<Bool>,
        speech: SpeechService,
        revealAccessibilityLabel: String = "Показать перевод"
    ) {
        self.word = word
        self._isRevealed = isRevealed
        self.speech = speech
        self.revealAccessibilityLabel = revealAccessibilityLabel
    }

    var body: some View {
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
                    accessibilityLabel: revealAccessibilityLabel
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
    }

    private func hintText(hasImage: Bool) -> String {
        hasImage ? L10n.Common.hintTapToRevealAll : L10n.Common.hintTapToRevealTranslation
    }
}
