import SwiftUI

struct SettingsView: View {
    @AppStorage("newWordsPerSession") private var newWordsPerSession: Int = 10
    @AppStorage("firstReviewTomorrow") private var firstReviewTomorrow: Bool = true

    var body: some View {
        Form {
            Section("New words session") {
                Stepper(value: $newWordsPerSession, in: 1...50, step: 1) {
                    HStack {
                        Text("Words per session")
                        Spacer()
                        Text("\(newWordsPerSession)")
                            .foregroundStyle(.secondary)
                    }
                }

                Toggle("First review tomorrow", isOn: $firstReviewTomorrow)

                Text(firstReviewTomorrow
                     ? "Words go to Review starting tomorrow."
                     : "Words can appear in Review today.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
