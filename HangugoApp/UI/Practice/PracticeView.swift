import SwiftUI

struct PracticeView: View {
    private let word: Word?

    @StateObject private var vm = PracticeViewModel()
    @FocusState private var isInputFocused: Bool

    init(word: Word? = nil) {
        self.word = word
    }

    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    if let word {
                        Section("Word") {
                            WordRow(word: word)
                        }
                    }

                    Section("Input") {
                        TextEditor(text: $vm.inputText)
                            .frame(minHeight: 120)
                            .focused($isInputFocused)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                    }

                    // ✅ Кнопки — отдельными строками (стабильно в List)
                    Section {
                        Button("Check") {
                            startCheck(includeStage2: false)
                        }
                        .disabled(vm.isLoading)

                        Button("Deep") {
                            startCheck(includeStage2: true)
                        }
                        .disabled(vm.isLoading)
                    }

                    if let error = vm.errorMessage {
                        Section("Error") {
                            Text(error)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let result = vm.result {
                        Section("Result") {
                            HStack {
                                Text(result.stage1.isCorrect ? "✅ Correct" : "⚠️ Needs fix")
                                Spacer()
                                Text("\(result.meta.score)/100")
                                    .foregroundStyle(.secondary)
                            }

                            Text("Confidence: \(String(format: "%.2f", result.meta.confidence))")
                                .foregroundStyle(.secondary)
                        }

                        if let corrected = result.stage1.corrected, !corrected.isEmpty {
                            Section("Suggested") {
                                Text(corrected)
                            }
                        }

                        if !result.stage1.mistakes.isEmpty {
                            Section("Mistakes") {
                                ForEach(result.stage1.mistakes) { m in
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(m.type).font(.headline)
                                        Text(m.explanationRu)
                                        if let s = m.suggestionRu {
                                            Text("→ \(s)")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }

                        if result.stage1.literalMeaningRu != nil || result.stage1.naturalTranslationRu != nil {
                            Section("Meaning") {
                                if let lit = result.stage1.literalMeaningRu {
                                    Text("Literal: \(lit)")
                                }
                                if let nat = result.stage1.naturalTranslationRu {
                                    Text("Natural: \(nat)")
                                        .foregroundStyle(.secondary)
                                }
                                if let rule = result.stage1.shortRuleRu {
                                    Text(rule)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        if let s2 = result.stage2 {
                            Section("Native thinking") {
                                Text(s2.nativeIntentRu)
                                Text(s2.whyThisFormRu)
                                    .foregroundStyle(.secondary)

                                if !s2.alternatives.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Alternatives")
                                            .font(.headline)
                                        ForEach(s2.alternatives) { alt in
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(alt.korean)
                                                    .font(.headline)
                                                Text(alt.nuanceRu)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }

                                if let check = s2.selfCheckRu {
                                    Text(check)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .scrollDismissesKeyboard(.immediately)
                .disabled(vm.isLoading)
                .navigationTitle("Practice")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Готово") {
                            isInputFocused = false
                        }
                    }
                }
                .onAppear {
                    vm.prefill(from: word)
                }

                // ✅ Loading overlay
                if vm.isLoading {
                    Color.black.opacity(0.05)
                        .ignoresSafeArea()

                    ProgressView("Проверяем…")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
            }
        }
    }

    private func startCheck(includeStage2: Bool) {
        // ✅ спрятать клавиатуру, чтобы увидеть tab bar после результата
        isInputFocused = false

        Task {
            await vm.check(includeStage2: includeStage2)
        }
    }
}
