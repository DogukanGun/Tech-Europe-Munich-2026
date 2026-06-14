import SwiftUI

/// Shown while the model loads. On first launch this includes the ~2 GB download.
struct ModelLoadingView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 24) {
                Image(systemName: "cpu")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.appAccent)

                Text("Preparing the model")
                    .font(.title2.bold())

                Text(model.modelStatus)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 8) {
                    ProgressView(value: model.downloadProgress)
                        .tint(Color.appAccent)
                    Text(progressLabel)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 24)

            Text("Keep the app open. This can take a few minutes on the first run.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 16)
                .padding(.horizontal, 32)

            Spacer()
            DisclaimerBanner()
        }
    }

    private var progressLabel: String {
        if model.downloadProgress <= 0 { return "Starting…" }
        if model.downloadProgress >= 1 { return "Ready" }
        return "\(Int(model.downloadProgress * 100))%"
    }
}
