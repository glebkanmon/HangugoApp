import SwiftUI

struct SessionProgressSectionView: View {
    let progress: Double
    let labelText: String
    let accessibilityText: String?

    init(progress: Double, labelText: String, accessibilityText: String? = nil) {
        self.progress = progress
        self.labelText = labelText
        self.accessibilityText = accessibilityText
    }

    var body: some View {
        Section {
            ProgressView(value: progress)

            HStack {
                Text(labelText)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .accessibilityLabel(accessibilityText ?? labelText)
        }
    }
}
