import SwiftUI

struct LearnView: View {
    @StateObject private var vm = LearnViewModel()

    var body: some View {
        List {
            Section("Overview") {

                NavigationLink {
                    NewWordsSessionView(words: vm.words)
                } label: {
                    HStack {
                        Text("New words available")
                        Spacer()
                        Text("\(vm.newWordsAvailable)")
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(vm.newWordsAvailable == 0 || vm.words.isEmpty)

                NavigationLink {
                    ReviewView()
                } label: {
                    HStack {
                        Text("Due today")
                        Spacer()
                        Text("\(vm.dueToday)")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Hangul") {
                Text("Alphabet (stub)")
                Text("Syllables (stub)")
                Text("Reading (stub)")
            }

            Section("Words") {
                if let error = vm.errorMessage {
                    Text(error).foregroundStyle(.secondary)
                } else if vm.words.isEmpty {
                    Text("Loading…").foregroundStyle(.secondary)
                } else {
                    NavigationLink("All words") {
                        WordsListView(words: vm.words)
                    }

                    let first = vm.words[0]
                    NavigationLink {
                        WordDetailView(word: first)
                    } label: {
                        WordRow(word: first)
                    }
                }
            }
        }
        .navigationTitle("Learn")
        .onAppear { vm.load() }
        .toolbar {
            NavigationLink {
                SettingsView()
            } label: {
                Image(systemName: "gear")
            }
        }
    }
}

#Preview {
    NavigationStack { LearnView() }
}
