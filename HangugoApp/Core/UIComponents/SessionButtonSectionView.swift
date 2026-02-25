import SwiftUI

struct SessionButtonAction: Identifiable {
    enum Style {
        case normal
        case destructive
    }

    let id = UUID()
    let title: String
    let style: Style
    let isEnabled: Bool
    let handler: () -> Void

    init(
        title: String,
        style: Style = .normal,
        isEnabled: Bool = true,
        handler: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.isEnabled = isEnabled
        self.handler = handler
    }
}

struct SessionButtonSectionView: View {
    let actions: [SessionButtonAction]

    var body: some View {
        Section {
            ForEach(actions) { action in
                Button(role: action.style == .destructive ? .destructive : nil) {
                    action.handler()
                } label: {
                    Text(action.title)
                        .fontWeight(.semibold)
                }
                .disabled(!action.isEnabled)
            }
        }
    }
}
