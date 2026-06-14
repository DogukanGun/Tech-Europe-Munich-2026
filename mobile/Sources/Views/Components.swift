import SwiftUI

extension Color {
    static let appBackground = Color(red: 0.06, green: 0.07, blue: 0.09)
    static let appCard = Color(red: 0.12, green: 0.13, blue: 0.16)
    static let appAccent = Color(red: 0.30, green: 0.62, blue: 0.92)
    static let appWarning = Color(red: 0.95, green: 0.62, blue: 0.20)
    static let appCaution = Color(red: 0.90, green: 0.45, blue: 0.40)
}

/// Persistent, unmissable reminder that this is not a diagnosis. Shown on every
/// screen of the flow.
struct DisclaimerBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.shield")
                .font(.footnote.weight(.semibold))
            Text("Educational only — not a medical diagnosis. Always consult a clinician.")
                .font(.caption2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.04))
    }
}

/// Full-width primary action button.
struct PrimaryButton: View {
    let title: String
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .background(enabled ? Color.appAccent : Color.gray.opacity(0.4))
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .disabled(!enabled)
    }
}

/// Secondary, low-emphasis text button.
struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .foregroundStyle(Color.appAccent)
    }
}

/// A titled card container.
struct InfoCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
