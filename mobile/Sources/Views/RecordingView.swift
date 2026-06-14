import SwiftUI
import UIKit

/// Live camera preview, posture guide, and the 30-second guided capture.
struct RecordingView: View {
    @EnvironmentObject private var model: AppModel
    @ObservedObject var recorder: CameraRecorder

    @State private var remaining = Int(AppModel.recordSeconds)
    @State private var countdownTimer: Timer?

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                preview
                postureGuide
                if recorder.isRecording { countdownOverlay }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            controls
            DisclaimerBanner()
        }
        .onAppear { recorder.prepare() }
        .onDisappear {
            countdownTimer?.invalidate()
            recorder.stopSession()
        }
    }

    // MARK: - Camera area

    @ViewBuilder
    private var preview: some View {
        switch recorder.state {
        case .ready:
            CameraPreview(session: recorder.session)
                .ignoresSafeArea(edges: .top)
        case .denied:
            message(
                icon: "video.slash",
                title: "Camera access needed",
                detail: "Enable camera access in Settings to record the check.",
                showSettings: true
            )
        case .failed(let reason):
            message(icon: "exclamationmark.triangle", title: "Camera unavailable", detail: reason)
        default:
            VStack(spacing: 12) {
                ProgressView().tint(.white)
                Text("Preparing camera…").foregroundStyle(.secondary)
            }
        }
    }

    private var postureGuide: some View {
        VStack {
            Text("Both hands in frame · arms out · wrists bent back")
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.black.opacity(0.45))
                .clipShape(Capsule())
                .padding(.top, 16)
            Spacer()
        }
        .opacity(recorder.state == .ready ? 1 : 0)
    }

    private var countdownOverlay: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Circle().fill(Color.appCaution).frame(width: 10, height: 10)
                Text("Recording — \(remaining)s")
                    .font(.headline.monospacedDigit())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.black.opacity(0.5))
            .clipShape(Capsule())
            .padding(.bottom, 24)
        }
    }

    // MARK: - Controls

    @ViewBuilder
    private var controls: some View {
        VStack(spacing: 8) {
            if recorder.isRecording {
                Text("Hold the posture steady. Recording stops automatically.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                PrimaryButton(
                    title: "Begin \(Int(AppModel.recordSeconds))-second recording",
                    enabled: recorder.state == .ready
                ) {
                    startCountdown()
                    model.beginCapture()
                }
                SecondaryButton(title: "Back to instructions") {
                    model.goToInstructions()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    // MARK: - Helpers

    private func startCountdown() {
        remaining = Int(AppModel.recordSeconds)
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            Task { @MainActor in
                if remaining > 0 { remaining -= 1 } else { timer.invalidate() }
            }
        }
    }

    private func message(icon: String, title: String, detail: String, showSettings: Bool = false) -> some View {
        VStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 40)).foregroundStyle(Color.appWarning)
            Text(title).font(.title3.bold())
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if showSettings {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .foregroundStyle(Color.appAccent)
            }
        }
        .padding(28)
    }
}
