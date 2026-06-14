import SwiftUI

/// First-run gate. The user must read and accept the scope before anything runs.
struct DisclaimerView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "hand.raised.fingers.spread")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.appAccent)
                        Text("Liver Flap Check")
                            .font(.largeTitle.bold())
                        Text("An on-device demo that watches a short clip of your hands for a flapping movement called *asterixis*.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 24)

                    InfoCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Please read before you start", systemImage: "info.circle")
                                .font(.headline)
                            bullet("This is **educational only**. It is **not** a medical device and does **not** diagnose any disease.")
                            bullet("A flapping pattern (asterixis) can occur in **several serious conditions** — including advanced liver disease, but also kidney or breathing problems and some medicines. It is a reason to **see a doctor**, not a diagnosis.")
                            bullet("A normal result **does not mean you are healthy.** Many liver conditions show no hand signs at all.")
                            bullet("Everything runs **on your device.** The video is analysed locally and is not uploaded.")
                            bullet("If you feel unwell, are confused, or notice yellow skin or eyes, **seek medical care now** — don't wait for this app.")
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }

            VStack(spacing: 8) {
                PrimaryButton(title: "I understand — continue") {
                    model.acceptDisclaimer()
                }
                Text("By continuing you confirm you understand this is not medical advice.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            DisclaimerBanner()
        }
    }

    private func bullet(_ markdown: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•").foregroundStyle(Color.appAccent)
            Text(.init(markdown))
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
