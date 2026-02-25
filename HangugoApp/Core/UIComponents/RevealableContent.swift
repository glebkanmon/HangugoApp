import SwiftUI

/// Wraps content that should be hidden until revealed.
/// - Applies blur + redaction while hidden
/// - Shows a subtle hint overlay
/// - Reveals on tap
struct RevealableContent<Content: View>: View {
    @Binding var isRevealed: Bool

    let hintText: String
    let accessibilityLabel: String?

    @ViewBuilder var content: () -> Content

    init(
        isRevealed: Binding<Bool>,
        hintText: String,
        accessibilityLabel: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._isRevealed = isRevealed
        self.hintText = hintText
        self.accessibilityLabel = accessibilityLabel
        self.content = content
    }

    var body: some View {
        ZStack {
            content()
                .blur(radius: isRevealed ? 0 : 12)
                .redacted(reason: isRevealed ? [] : .placeholder)
                .opacity(isRevealed ? 1 : 0.95)

            hintOverlay
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isRevealed {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isRevealed = true
                }
            }
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(accessibilityLabel ?? "Показать ответ")
    }

    @ViewBuilder
    private var hintOverlay: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.tap")
                .foregroundStyle(.secondary)
            Text(hintText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .opacity(isRevealed ? 0 : 1)
        .allowsHitTesting(false)
        .accessibilityHidden(isRevealed)
    }
}
