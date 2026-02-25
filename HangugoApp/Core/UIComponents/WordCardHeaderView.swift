import SwiftUI

struct WordCardHeaderView: View {
    let korean: String
    let transcriptionRR: String?
    let onSpeak: () -> Void

    init(korean: String, transcriptionRR: String?, onSpeak: @escaping () -> Void) {
        self.korean = korean
        self.transcriptionRR = transcriptionRR
        self.onSpeak = onSpeak
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(korean)
                    .font(.system(size: 34, weight: .semibold))

                if let rr = normalizedRR(transcriptionRR) {
                    Text(rr)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            SpeechButton(accessibilityLabel: "Произнести слово", action: onSpeak)
        }
    }

    private func normalizedRR(_ rr: String?) -> String? {
        guard let rr = rr?.trimmingCharacters(in: .whitespacesAndNewlines), !rr.isEmpty else { return nil }
        return rr
    }
}
