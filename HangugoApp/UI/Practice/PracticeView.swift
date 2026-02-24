import SwiftUI
import Combine

struct PracticeView: View {
    private let word: Word?

    @StateObject private var vm = PracticeViewModel()
    @FocusState private var isInputFocused: Bool

    // Limits
    private let softHangulLimit = 200
    private let hardHangulLimit = 400
    private let maxTotalChars = 1000

    @State private var hangulSyllableCount: Int = 0
    @State private var isAdjustingText: Bool = false

    private enum Anchor {
        static let input = "INPUT_ANCHOR"
        static let result = "RESULT_ANCHOR"
    }

    init(word: Word? = nil) {
        self.word = word
    }

    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                Form {
                    if let word {
                        Section("Слово") {
                            WordRow(word: word)
                        }
                    }

                    Section {
                        TextField("Напиши фразу на корейском…", text: $vm.inputText, axis: .vertical)
                            .lineLimit(3...8)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .focused($isInputFocused)
                            .submitLabel(.done)
                            .onSubmit { isInputFocused = false }
                            .id(Anchor.input)
                            .onChange(of: vm.inputText) { newValue in
                                guard !isAdjustingText else { return }
                                isAdjustingText = true

                                hangulSyllableCount = countHangulSyllables(in: newValue)

                                if newValue.count > maxTotalChars || hangulSyllableCount > hardHangulLimit {
                                    let limited = enforceInputLimits(newValue)
                                    if limited != newValue {
                                        vm.inputText = limited
                                        hangulSyllableCount = countHangulSyllables(in: limited)
                                    }
                                }

                                isAdjustingText = false
                            }
                    } header: {
                        Text("Ввод")
                    } footer: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("한글 \(hangulSyllableCount)/\(hardHangulLimit)  •  \(vm.inputText.count)/\(maxTotalChars)")
                                .foregroundStyle(.secondary)

                            if hangulSyllableCount > softHangulLimit {
                                Text("Совет: лучше держать фразу короче — так ответы AI будут быстрее и стабильнее.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Section {
                        Button {
                            startCheck(includeStage2: false)
                        } label: {
                            Text("Проверить")
                                .fontWeight(.semibold)
                        }
                        .disabled(vm.isLoading)

                        Button {
                            startCheck(includeStage2: true)
                        } label: {
                            Text("Подробно")
                                .fontWeight(.semibold)
                        }
                        .disabled(vm.isLoading)
                    }

                    if let error = vm.errorMessage {
                        Section("Ошибка") {
                            Text(error)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if vm.canRecheck {
                        Section("Результат") {
                            HStack(alignment: .center, spacing: 12) {
                                Image(systemName: "exclamationmark.circle")
                                    .foregroundStyle(.secondary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Текст изменён")
                                    Text("Результат ниже относится к предыдущей версии. Нажми «Проверить снова» (\(vm.lastModeLabel)).")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Button {
                                    startRecheck()
                                } label: {
                                    Text("Проверить снова")
                                        .fontWeight(.semibold)
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    if let result = vm.result {
                        Section("Результат") {
                            HStack {
                                Text(result.stage1.isCorrect ? "✅ Правильно" : "⚠️ Нужно исправить")
                                Spacer()
                                Text("\(result.meta.score)/100")
                                    .foregroundStyle(.secondary)
                            }
                            .id(Anchor.result)

                            Text("Уверенность: \(String(format: "%.2f", result.meta.confidence))")
                                .foregroundStyle(.secondary)
                        }

                        if let corrected = result.stage1.corrected, !corrected.isEmpty {
                            Section("Исправленный вариант") {
                                Text(corrected)

                                Button {
                                    vm.applyCorrection()
                                    DispatchQueue.main.async {
                                        withAnimation {
                                            proxy.scrollTo(Anchor.input, anchor: .top)
                                        }
                                        isInputFocused = true
                                    }
                                } label: {
                                    Text("Применить исправление")
                                        .fontWeight(.semibold)
                                }
                                .disabled(
                                    vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines) ==
                                    corrected.trimmingCharacters(in: .whitespacesAndNewlines)
                                )
                            }
                        }

                        if !result.stage1.mistakes.isEmpty {
                            Section("Ошибки") {
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
                            Section("Смысл") {
                                if let lit = result.stage1.literalMeaningRu {
                                    Text("Дословно: \(lit)")
                                }
                                if let nat = result.stage1.naturalTranslationRu {
                                    Text("Естественно: \(nat)")
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
                            Section("Как сказал бы носитель") {
                                Text(s2.nativeIntentRu)
                                Text(s2.whyThisFormRu)
                                    .foregroundStyle(.secondary)

                                if !s2.alternatives.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Варианты")
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

                                if let check = s2.selfCheckRu, !check.isEmpty {
                                    Text(check)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .onReceive(vm.$result) { newValue in
                    guard newValue != nil else { return }
                    DispatchQueue.main.async {
                        withAnimation {
                            proxy.scrollTo(Anchor.result, anchor: .top)
                        }
                    }
                }
                .scrollDismissesKeyboard(.immediately)
                .disabled(vm.isLoading)
                .navigationTitle("Практика")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button {
                            isInputFocused = false
                        } label: {
                            Text("Готово")
                                .fontWeight(.semibold)
                        }
                    }
                }
                .onAppear {
                    vm.prefill(from: word)
                    hangulSyllableCount = countHangulSyllables(in: vm.inputText)
                }
            }

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

    // MARK: - Actions

    private func startCheck(includeStage2: Bool) {
        isInputFocused = false
        Task { await vm.check(includeStage2: includeStage2) }
    }

    private func startRecheck() {
        isInputFocused = false
        Task { await vm.recheck() }
    }

    // MARK: - Limits helpers

    private func enforceInputLimits(_ text: String) -> String {
        var working = text
        if working.count > maxTotalChars {
            working = String(working.prefix(maxTotalChars))
        }

        var out = ""
        out.reserveCapacity(working.count)

        var hangulCount = 0
        for ch in working {
            if isHangulSyllable(ch) {
                if hangulCount >= hardHangulLimit { break }
                hangulCount += 1
            }
            out.append(ch)
        }
        return out
    }

    private func countHangulSyllables(in text: String) -> Int {
        var count = 0
        for ch in text where isHangulSyllable(ch) { count += 1 }
        return count
    }

    private func isHangulSyllable(_ ch: Character) -> Bool {
        // Hangul Syllables block: AC00–D7A3
        let scalars = String(ch).unicodeScalars
        guard scalars.count == 1, let s = scalars.first else { return false }
        return (0xAC00...0xD7A3).contains(Int(s.value))
    }
}
