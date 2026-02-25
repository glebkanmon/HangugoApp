import SwiftUI

struct SessionDoneSectionView: View {
    let title: String
    let subtitle: String
    let actionTitle: String?
    let destination: AnyView?

    init(
        title: String,
        subtitle: String,
        actionTitle: String? = nil,
        destination: AnyView? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.destination = destination
    }

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .foregroundStyle(.secondary)

                if let actionTitle, let destination {
                    NavigationLink(actionTitle) {
                        destination
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}
