import SwiftUI

/// Shown while frames are sampled and the model reasons over them.
struct AnalyzingView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 20) {
                ProgressView()
                    .controlSize(.large)
                    .tint(Color.appAccent)
                Text("Analyzing on device")
                    .font(.title2.bold())
                Text("Looking at the hand movement across the clip. Nothing is uploaded.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer()
            DisclaimerBanner()
        }
    }
}
