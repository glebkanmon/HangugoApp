import SwiftUI

struct WordsListView: View {
    let words: [Word]

    var body: some View {
        List {
            ForEach(words) { word in
                NavigationLink {
                    WordDetailView(word: word)
                } label: {
                    WordRow(word: word)
                }
            }
        }
        .navigationTitle("Words")
    }
}
#Preview {
    WordsListView(words: [])
}
