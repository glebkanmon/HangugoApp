// UI/Components/WordRow.swift

import SwiftUI

struct WordRow: View {
    let word: Word

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(word.korean)
                    .foregroundStyle(.primary)

                Spacer(minLength: 8)

                if let rr = normalizedRR {
                    Text(rr)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            Text(word.translation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var normalizedRR: String? {
        guard let rr = word.transcriptionRR?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rr.isEmpty else { return nil }
        return rr
    }
}
