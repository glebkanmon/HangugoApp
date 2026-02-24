// UI/Learn/CategoryPickerView.swift

import SwiftUI

struct CategoryPickerView: View {
    @StateObject private var vm: CategoryPickerViewModel

    init(words: [Word]) {
        _vm = StateObject(wrappedValue: CategoryPickerViewModel(words: words))
    }

    var body: some View {
        List {
            // 1) Подборки — наверху
            if !vm.listTags.isEmpty {
                Section(L10n.Categories.listsSection) {
                    ForEach(vm.listTags, id: \.self) { tag in
                        row(tag: tag)
                    }
                }
            }

            // 2) Темы
            if !vm.topicTags.isEmpty {
                Section(L10n.Categories.topicsSection) {
                    ForEach(vm.topicTags, id: \.self) { tag in
                        row(tag: tag)
                    }
                }
            }

            // 3) Части речи
            if !vm.posTags.isEmpty {
                Section(L10n.Categories.posSection) {
                    ForEach(vm.posTags, id: \.self) { tag in
                        row(tag: tag)
                    }
                }
            }

            // 4) Подсказка + сброс — внизу
            Section {
                Text(L10n.Categories.allHint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button(role: .destructive) {
                    vm.reset()
                } label: {
                    Text(L10n.Categories.reset)
                }
            }
        }
        .navigationTitle(L10n.Categories.navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { vm.load() }
    }

    private func row(tag: String) -> some View {
        let isSelected = vm.selectedTags.contains(tag)

        return Button {
            vm.toggle(tag)
        } label: {
            HStack {
                Text(L10n.Categories.displayName(for: tag))
                    .foregroundStyle(.primary) // ✅ не синий

                Spacer()

                Image(systemName: isSelected ? "checkmark.square" : "square")
                    .foregroundStyle(.secondary) // ✅ чекбокс спокойным цветом
                    .imageScale(.large)
            }
        }
        .buttonStyle(.plain) // ✅ выглядит как обычная строка списка, без синего текста
    }
}
