import SwiftUI

struct WordRow: View {
    let word: Word

    var body: some View {
        HStack(spacing: 12) {
            if let imageName = word.imageAssetName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(word.korean)
                    .font(.headline)

                Text(word.translation)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
#Preview {
    WordRow(word: Word(id: "test", korean: "글렙", translation: "Глеб", example: nil, exampleTranslation: nil, imageAssetName: nil, audioKey: nil, tags: nil))
}
