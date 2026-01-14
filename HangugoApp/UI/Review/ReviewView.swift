import SwiftUI

struct ReviewView: View {
    @StateObject private var vm = ReviewViewModel()
    @State private var isAnswerRevealed: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section("Today") {
                    if let error = vm.errorMessage {
                        Text(error).foregroundStyle(.secondary)
                    } else {
                        Text("Cards due today: \(vm.dueCount)")
                    }
                }

                if vm.dueCount == 0 {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("All done ✅")
                                .font(.headline)
                            Text("You can practice sentences instead.")
                                .foregroundStyle(.secondary)

                            NavigationLink("Go to Practice") {
                                PracticeView()
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } else if let word = vm.currentWord {
                    Section("Card") {
                        Text(word.korean)
                            .font(.headline)

                        if isAnswerRevealed {
                            Text(word.translation)
                                .foregroundStyle(.secondary)

                            if let example = word.example, !example.isEmpty {
                                Text(example)
                            }
                        } else {
                            Button("Reveal translation") {
                                isAnswerRevealed = true
                            }
                        }
                    }

                    Section("Rating") {
                        Button("Hard") { rateAndAdvance(.hard) }.disabled(!isAnswerRevealed)
                        Button("Normal") { rateAndAdvance(.normal) }.disabled(!isAnswerRevealed)
                        Button("Easy") { rateAndAdvance(.easy) }.disabled(!isAnswerRevealed)
                    }
                } else {
                    Section {
                        Text("Could not find the word for the current SRS item.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Review")
            .onAppear {
                vm.load()
                isAnswerRevealed = false
            }
        }
    }
    
    private func rateAndAdvance(_ rating: ReviewRating) {
        vm.rateCurrent(rating)
        isAnswerRevealed = false
    }
}
