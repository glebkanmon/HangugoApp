import SwiftUI

struct ReviewView: View {
    @StateObject private var vm = ReviewViewModel()
    @State private var isAnswerRevealed: Bool = false

    var body: some View {
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
                    VStack(alignment: .leading, spacing: 10) {
                        Text(word.korean)
                            .font(.system(size: 34, weight: .semibold))

                        revealableAnswerBlock(
                            isRevealed: isAnswerRevealed,
                            hint: "Tap to reveal translation and image",
                            hasImage: word.imageAssetName != nil
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

                        } onReveal: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isAnswerRevealed = true
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }

                if let example = word.example, !example.isEmpty {
                    Section("Example") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(example)

                            if let exTr = word.exampleTranslation, !exTr.isEmpty {
                                Text(exTr)
                                    .foregroundStyle(.secondary)
                                    .blur(radius: isAnswerRevealed ? 0 : 12)
                                    .redacted(reason: isAnswerRevealed ? [] : .placeholder)
                                    .opacity(isAnswerRevealed ? 1 : 0.95)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if !isAnswerRevealed {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                isAnswerRevealed = true
                                            }
                                        }
                                    }
                            }
                        }
                    }
                }

                Section("Rating") {
                    Button {
                        rateAndAdvance(.hard)
                    } label: {
                        Label("Hard", systemImage: "tortoise")
                            .fontWeight(.semibold)
                    }
                    .disabled(!isAnswerRevealed)

                    Button {
                        rateAndAdvance(.normal)
                    } label: {
                        Label("Normal", systemImage: "figure.walk")
                            .fontWeight(.semibold)
                    }
                    .disabled(!isAnswerRevealed)

                    Button {
                        rateAndAdvance(.easy)
                    } label: {
                        Label("Easy", systemImage: "hare")
                            .fontWeight(.semibold)
                    }
                    .disabled(!isAnswerRevealed)
                }
            } else {
                Section {
                    Text("Could not find the word for the current SRS item.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .id(vm.currentWord?.id ?? "no_word")
        .onChange(of: vm.currentWord?.id) { _ in
            isAnswerRevealed = false
        }
        .navigationTitle("Review")
        .onAppear {
            vm.load()
            isAnswerRevealed = false
        }
    }

    private func rateAndAdvance(_ rating: ReviewRating) {
        vm.rateCurrent(rating)
        isAnswerRevealed = false
    }

    @ViewBuilder
    private func revealableAnswerBlock<Content: View>(
        isRevealed: Bool,
        hint: String,
        hasImage: Bool,
        @ViewBuilder content: () -> Content,
        onReveal: @escaping () -> Void
    ) -> some View {
        ZStack {
            content()
                .blur(radius: isRevealed ? 0 : 12)
                .redacted(reason: isRevealed ? [] : .placeholder)
                .opacity(isRevealed ? 1 : 0.95)

            HStack(spacing: 8) {
                Image(systemName: "hand.tap")
                    .foregroundStyle(.secondary)
                Text(hasImage ? hint : "Tap to reveal translation")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .opacity(isRevealed ? 0 : 1)
            .allowsHitTesting(false)
            .accessibilityHidden(isRevealed)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isRevealed {
                onReveal()
            }
        }
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    NavigationStack { ReviewView() }
}
