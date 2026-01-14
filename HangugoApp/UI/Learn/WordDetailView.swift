import SwiftUI

struct WordDetailView: View {
    let word: Word

    var body: some View {
        List {
            Section {
                Text(word.translation)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            if let example = word.example, !example.isEmpty {
                Section("Example") {
                    Text(example)
                }
            }

            Section {
                NavigationLink("Try in Practice") {
                    PracticeView(word: word)
                }
            }
        }
        .navigationTitle(word.korean)
        .navigationBarTitleDisplayMode(.large)
    }
}
