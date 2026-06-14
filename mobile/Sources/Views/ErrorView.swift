import SwiftUI

/// Generic recoverable error state — sends the user back to instructions to retry.
struct ErrorView: View {
    @EnvironmentObject private var model: AppModel
    let message: String

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.appWarning)
                Text("Something went wrong")
                    .font(.title2.bold())
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            Spacer()
            PrimaryButton(title: "Try again") {
                model.goToInstructions()
            }
            .padding(.horizontal, 20)
            DisclaimerBanner()
        }
    }
}
