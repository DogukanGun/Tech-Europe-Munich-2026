import AVFoundation
import SwiftUI
import UIKit

enum CameraError: LocalizedError {
    case busy
    case unknown

    var errorDescription: String? {
        switch self {
        case .busy: return "A recording is already in progress."
        case .unknown: return "Recording failed unexpectedly."
        }
    }
}

/// Wraps an `AVCaptureSession` that records a short clip to a temp file.
/// Session configuration and recording happen on a dedicated queue; published
/// state is mirrored to the main thread for SwiftUI.
// @unchecked Sendable: all mutable state is confined to `sessionQueue` and
// @Published updates are dispatched to the main thread, so cross-thread capture
// of `self` in the AVFoundation callbacks is safe.
final class CameraRecorder: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate, @unchecked Sendable {

    enum State: Equatable {
        case idle
        case configuring
        case ready
        case denied
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var isRecording = false

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "de.certhub.liverflapcheck.session")
    private let movieOutput = AVCaptureMovieFileOutput()
    private var continuation: CheckedContinuation<URL, Error>?

    // MARK: - Setup

    func prepare() {
        setState(.configuring)
        Task {
            let granted = await Self.requestCameraAccess()
            guard granted else {
                self.setState(.denied)
                return
            }
            self.sessionQueue.async { self.configureSession() }
        }
    }

    private static func requestCameraAccess() async -> Bool {
        // Microphone is requested too (clip may include audio) but is not required.
        _ = await withCheckedContinuation { c in
            AVCaptureDevice.requestAccess(for: .audio) { c.resume(returning: $0) }
        }
        return await withCheckedContinuation { c in
            AVCaptureDevice.requestAccess(for: .video) { c.resume(returning: $0) }
        }
    }

    private func configureSession() {
        // Returning to the screen: the session is already configured, so just
        // resume it instead of re-adding inputs/outputs (which would fail).
        if !session.inputs.isEmpty {
            if !session.isRunning { session.startRunning() }
            setState(.ready)
            return
        }

        session.beginConfiguration()
        session.sessionPreset = .high

        // Front camera so the user can prop the phone facing them, see both hands,
        // and hold the posture while the clip records.
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            ?? AVCaptureDevice.default(for: .video),
            let videoInput = try? AVCaptureDeviceInput(device: camera),
            session.canAddInput(videoInput)
        else {
            session.commitConfiguration()
            setState(.failed("No usable camera was found."))
            return
        }
        session.addInput(videoInput)

        if let mic = AVCaptureDevice.default(for: .audio),
            let micInput = try? AVCaptureDeviceInput(device: mic),
            session.canAddInput(micInput) {
            session.addInput(micInput)
        }

        guard session.canAddOutput(movieOutput) else {
            session.commitConfiguration()
            setState(.failed("This device cannot record video."))
            return
        }
        session.addOutput(movieOutput)
        session.commitConfiguration()

        session.startRunning()
        setState(.ready)
    }

    // MARK: - Recording

    /// Records up to `seconds` and resolves with the file URL. The output
    /// auto-stops at `maxRecordedDuration`.
    func record(maxDuration seconds: Double) async throws -> URL {
        try await withCheckedThrowingContinuation { cont in
            sessionQueue.async {
                guard !self.movieOutput.isRecording else {
                    cont.resume(throwing: CameraError.busy)
                    return
                }
                self.continuation = cont
                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent("liverflap-\(UUID().uuidString).mov")
                self.movieOutput.maxRecordedDuration = CMTime(seconds: seconds, preferredTimescale: 600)
                self.movieOutput.startRecording(to: url, recordingDelegate: self)
                self.setRecording(true)
            }
        }
    }

    func cancelRecording() {
        sessionQueue.async {
            if self.movieOutput.isRecording { self.movieOutput.stopRecording() }
        }
    }

    func stopSession() {
        sessionQueue.async {
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    // MARK: - AVCaptureFileOutputRecordingDelegate

    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        setRecording(false)
        // Hitting maxRecordedDuration surfaces as an error but is a successful clip.
        let success: Bool
        if let nsError = error as NSError? {
            success = (nsError.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool) ?? false
        } else {
            success = true
        }
        sessionQueue.async {
            let cont = self.continuation
            self.continuation = nil
            if success {
                cont?.resume(returning: outputFileURL)
            } else {
                cont?.resume(throwing: error ?? CameraError.unknown)
            }
        }
    }

    // MARK: - Helpers

    private func setState(_ newState: State) {
        DispatchQueue.main.async { self.state = newState }
    }

    private func setRecording(_ value: Bool) {
        DispatchQueue.main.async { self.isRecording = value }
    }
}

/// SwiftUI wrapper around an `AVCaptureVideoPreviewLayer`.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
