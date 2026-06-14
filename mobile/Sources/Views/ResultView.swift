import SwiftUI
import UIKit

/// Presents the result with conservative, safety-gated copy. The headline state
/// is decided by the app (not the model); the model's own assessment + summary are
/// shown as supporting detail. Nothing here asserts a diagnosis.
struct ResultView: View {
    @EnvironmentObject private var model: AppModel
    let result: AsterixisResult

    private static let okGreen = Color(red: 0.30, green: 0.78, blue: 0.52)

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    Text(.init(bodyText))
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if result.outcome == .flapDetected {
                        urgentCard
                    }

                    if !result.summary.isEmpty {
                        summaryCard
                    }

                    detailsCard

                    Text("This is **not a diagnosis** and the model can be wrong in both directions.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 24)
            }

            actions
            DisclaimerBanner()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 52))
                .foregroundStyle(accent)
            Text(title)
                .font(.title.bold())
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var urgentCard: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("Seek medical care", systemImage: "cross.case")
                    .font(.headline)
                    .foregroundStyle(Color.appCaution)
                Text("Please contact a doctor soon. If you also have confusion, drowsiness, yellow skin or eyes, vomiting blood, or trouble breathing, seek urgent or emergency care now.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// The model's own plain-language summary.
    private var summaryCard: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("AI summary", systemImage: "text.bubble")
                    .font(.headline)
                Text(result.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var detailsCard: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("What the check observed")
                    .font(.headline)
                detailRow("Posture held", result.postureValid ? "Yes" : "No")
                detailRow("Flap events seen", "\(result.flapEvents)")
                detailRow("Movement pattern", result.pattern.rawValue.capitalized)
                detailRow("Between hands", symmetryText)
                detailRow("Model decision", decisionText)
                detailRow("Model confidence", result.confidence.rawValue.capitalized)
                if !result.note.isEmpty {
                    Divider().overlay(Color.white.opacity(0.1))
                    Text(result.note)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if result.confidence == .low {
                    Text("Low confidence — consider recording again in steadier, brighter conditions.")
                        .font(.footnote)
                        .foregroundStyle(Color.appWarning)
                }
            }
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.subheadline.weight(.medium))
        }
    }

    // MARK: - Actions

    @ViewBuilder
    private var actions: some View {
        VStack(spacing: 8) {
            if result.outcome == .flapDetected {
                PrimaryButton(title: "Find medical care nearby") { openCareSearch() }
                SecondaryButton(title: "Run the check again") { model.goToInstructions() }
            } else if result.outcome == .invalidPosture {
                PrimaryButton(title: "Record again") { model.goToInstructions() }
            } else {
                PrimaryButton(title: "Run the check again") { model.goToInstructions() }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func openCareSearch() {
        if let url = URL(string: "http://maps.apple.com/?q=doctor") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Copy

    private var iconName: String {
        switch result.outcome {
        case .invalidPosture: return "arrow.clockwise.circle"
        case .flapDetected: return "exclamationmark.triangle.fill"
        case .noFlap: return "checkmark.circle"
        }
    }

    private var accent: Color {
        switch result.outcome {
        case .invalidPosture: return Color.appAccent
        case .flapDetected: return Color.appCaution
        case .noFlap: return Self.okGreen
        }
    }

    private var title: String {
        switch result.outcome {
        case .invalidPosture: return "Couldn't perform the check"
        case .flapDetected: return "An irregular flapping pattern was seen"
        case .noFlap: return "No flapping pattern was seen"
        }
    }

    private var bodyText: String {
        switch result.outcome {
        case .invalidPosture:
            return "We couldn't clearly see both arms extended with the wrists bent back for long enough. Please record again with both hands clearly in frame and held steady."
        case .flapDetected:
            return "This clip showed an **irregular flapping** of the hands. A flap can occur in **several serious conditions** — including advanced liver disease, but also kidney or breathing problems, or as a side effect of some medicines. It is a reason to **see a doctor promptly**, not a diagnosis."
        case .noFlap:
            return "This clip did **not** show a flapping pattern. **This does not rule anything out** — many conditions, including early liver disease, show no hand signs. If you have symptoms or concerns, please see a clinician."
        }
    }

    private var symmetryText: String {
        switch result.symmetry {
        case .asynchronous: return "Out of sync"
        case .synchronous: return "In sync"
        case .na, .unknown: return "—"
        }
    }

    private var decisionText: String {
        switch result.decision {
        case .flap: return "Flap"
        case .noFlap: return "No flap"
        case .inconclusive: return "Inconclusive"
        case .unknown: return "—"
        }
    }
}
