import SwiftUI

/// Explains how to perform the asterixis hold and frame the shot.
struct InstructionsView: View {
    @EnvironmentObject private var model: AppModel

    private let steps: [(icon: String, title: String, detail: String)] = [
        ("iphone.gen3", "Prop the phone facing you",
         "Stand the phone up so the front camera sees you — you'll need both hands free."),
        ("hand.raised.fingers.spread", "Hold both hands out",
         "Extend both arms toward the camera, bend your wrists back (palms toward you), and spread your fingers."),
        ("waveform.path", "Watch for shaking",
         "The test looks for sudden, irregular shaking or flapping of the held hands — keep them as still as you can."),
        ("eye.slash", "Hold still ~10 seconds",
         "Keep holding (eyes closed helps), in good even lighting, with both hands clearly in frame."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("How to do the check")
                        .font(.largeTitle.bold())
                        .padding(.top, 24)

                    Text("This looks for *asterixis* — a brief, irregular flapping of the hands while they're held out.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 12) {
                        ForEach(Array(steps.enumerated()), id: \.offset) { _, step in
                            InfoCard {
                                HStack(alignment: .top, spacing: 14) {
                                    Image(systemName: step.icon)
                                        .font(.title2)
                                        .foregroundStyle(Color.appAccent)
                                        .frame(width: 32)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(step.title).font(.headline)
                                        Text(.init(step.detail))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }

            PrimaryButton(title: "Set up the camera") {
                model.goToRecording()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            DisclaimerBanner()
        }
    }
}
