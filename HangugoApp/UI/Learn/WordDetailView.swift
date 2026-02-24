// UI/Learn/WordDetailView.swift

import SwiftUI

struct WordDetailView: View {
    let word: Word

    var body: some View {
        List {
            Section(L10n.Common.wordSection) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(word.korean)
                        .font(.system(size: 34, weight: .semibold))

                    Text(word.translation)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }

            Section(L10n.WordDetail.translationSection) {
                Text(word.translation)
            }

            if let imageName = word.imageAssetName {
                Section(L10n.WordDetail.imageSection) {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.vertical, 2)
                }
            }

            Section(L10n.Common.exampleSection) {
                if let example = word.example, !example.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(example)

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
                    PracticeView()
                }
            }
        }
        .navigationTitle(word.korean)
        .navigationBarTitleDisplayMode(.inline)
    }
}

