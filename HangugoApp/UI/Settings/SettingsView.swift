// UI/Settings/SettingsView.swift

import SwiftUI

struct SettingsView: View {
    @AppStorage("newWordsPerSession") private var newWordsPerSession: Int = 10
    @AppStorage("firstReviewTomorrow") private var firstReviewTomorrow: Bool = true

    var body: some View {
        Form {
            Section(L10n.Settings.newWordsSessionSection) {
                Stepper(value: $newWordsPerSession, in: 1...50, step: 1) {
                    HStack {
                        Text(L10n.Settings.wordsPerSession)
                        Spacer()
                        Text("\(newWordsPerSession)")
                            .foregroundStyle(.secondary)
                    }
                }

                Toggle(L10n.Settings.firstReviewTomorrow, isOn: $firstReviewTomorrow)

                Text(firstReviewTomorrow
                     ? L10n.Settings.firstReviewTomorrowOnHint
                     : L10n.Settings.firstReviewTomorrowOffHint)
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(L10n.Settings.navTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
