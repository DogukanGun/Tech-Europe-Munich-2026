import SwiftUI

/// Drives the single linear flow and owns the model + recorder.
@MainActor
final class AppModel: ObservableObject {

    enum Step {
        case disclaimer
        case loadingModel
        case instructions
        case recording
        case analyzing
        case result(AsterixisResult)
        case error(String)
    }

    @Published var step: Step = .disclaimer
    @Published var downloadProgress: Double = 0
    @Published var modelStatus: String = ""

    let recorder = CameraRecorder()
    private let vlm = GemmaVLMService()

    /// How long the guided hold/recording lasts. (Clinically a longer hold catches
    /// more flaps, but kept short per product choice.)
    static let recordSeconds: Double = 10

    // MARK: - Flow

    func acceptDisclaimer() {
        step = .loadingModel
        Task { await loadModel() }
    }

    private func loadModel() async {
        modelStatus = "Loading the on-device model.\nThe first run downloads about 2 GB over Wi-Fi."
        do {
            try await vlm.load { fraction in
                Task { @MainActor in self.downloadProgress = fraction }
            }
            downloadProgress = 1
            step = .instructions
        } catch {
            step = .error("Couldn't load the model: \(error.localizedDescription)")
        }
    }

    func goToRecording() {
        step = .recording
    }

    /// Called from the recording screen once the user is in position.
    func beginCapture() {
        Task { await runRecording() }
    }

    private func runRecording() async {
        do {
            let url = try await recorder.record(maxDuration: Self.recordSeconds)
            step = .analyzing
            await analyze(url: url)
        } catch {
            step = .error("Recording failed: \(error.localizedDescription)")
        }
    }

    private func analyze(url: URL) async {
        defer { try? FileManager.default.removeItem(at: url) }
        do {
            // Measure real motion first (reliable), then let the VLM describe it.
            let motion = await MotionAnalyzer.analyze(url: url)
            let raw = try await vlm.analyze(videoURL: url, motionHint: motion.level)
            if var result = AsterixisResult.parse(from: raw) {
                result.applyMotion(motion.level)   // motion overrides the VLM's shaking call
                step = .result(result)
                // Best-effort persist to the backend (which writes to MongoDB). No-op
                // until BackendConfig.resultEndpoint is set; never blocks the UI.
                Task { await ResultStore.save(result) }
            } else {
                step = .error("The model's response couldn't be read. Please record again.")
            }
        } catch {
            step = .error("Analysis failed: \(error.localizedDescription)")
        }
    }

    func goToInstructions() {
        step = .instructions
    }
}
