import SwiftUI

struct ExampleBlockView: View {
    let example: String
    let exampleTranslation: String?

    @Binding var isRevealed: Bool

    let onSpeak: () -> Void

    init(
        example: String,
        exampleTranslation: String?,
        isRevealed: Binding<Bool>,
        onSpeak: @escaping () -> Void
    ) {
        self.example = example
        self.exampleTranslation = exampleTranslation
        self._isRevealed = isRevealed
        self.onSpeak = onSpeak
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(example)

                Spacer()

                SpeechButton(accessibilityLabel: "Произнести пример", action: onSpeak)
            }

            if let tr = normalized(exampleTranslation) {
                // translation reveals вместе с основным reveal: один источник правды
                Text(tr)
                    .foregroundStyle(.secondary)
                    .blur(radius: isRevealed ? 0 : 12)
                    .redacted(reason: isRevealed ? [] : .placeholder)
                    .opacity(isRevealed ? 1 : 0.95)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !isRevealed {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isRevealed = true
                            }
                        }
                    }
            }
        }
    }

    private func normalized(_ s: String?) -> String? {
        guard let s = s?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        return s
    }
}
