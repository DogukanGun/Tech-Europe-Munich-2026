import Foundation
import CoreGraphics
import MLXLMCommon
import MLXVLM
import MLXHuggingFace
import HuggingFace
import Tokenizers

enum VLMServiceError: LocalizedError {
    case notLoaded
    case emptyOutput

    var errorDescription: String? {
        switch self {
        case .notLoaded: return "The model is not loaded yet."
        case .emptyOutput: return "The model returned no output."
        }
    }
}

/// Loads Gemma 4 E2B (vision, 4-bit) on-device and runs the asterixis check.
///
/// First load downloads the weights (~2 GB) from Hugging Face into the app
/// container and caches them; later launches reuse the cache. All inference is
/// on-device — no frames or video leave the phone.
///
/// `mlx-swift-lm` doesn't bundle a Hugging Face client, so the download +
/// tokenizer are supplied via the `#huggingFaceLoadModelContainer` macro, which
/// bridges `HuggingFace.HubClient` + the `Tokenizers` loader.
final class GemmaVLMService {

    /// Swap to `.gemma4_E4B_it_4bit` (better, ~4 GB) or `.gemma3_4B_qat_4bit`
    /// (most battle-tested MLX vision) if E2B output is poor on the target device.
    private let configuration = VLMRegistry.gemma4_E2B_it_4bit

    private var container: ModelContainer?

    var isLoaded: Bool { container != nil }

    /// Loads (downloading on first run). `progress` is reported as a fraction 0...1.
    func load(progress: @escaping @Sendable (Double) -> Void) async throws {
        if container != nil { return }
        // NOTE: progressHandler must be an explicit labeled argument — the macro
        // reads it from the argument list, so a trailing closure would be ignored.
        container = try await #huggingFaceLoadModelContainer(
            configuration: configuration,
            progressHandler: { p in progress(p.fractionCompleted) }
        )
    }

    /// Samples frames from the recorded clip and asks the model to describe the
    /// hand motion. Returns the raw model text (parsed later by `AsterixisResult`).
    func analyze(videoURL: URL, motionHint: MotionLevel? = nil, frameCount: Int = 12) async throws -> String {
        guard let container else { throw VLMServiceError.notLoaded }

        let frames = try await FrameSampler.sampleVideoFrames(url: videoURL, count: frameCount)

        let session = ChatSession(
            container,
            generateParameters: GenerateParameters(maxTokens: 400, temperature: 0.2),
            processing: .init(resize: CGSize(width: 512, height: 512))
        )

        var prompt = AsterixisPrompt.text
        if let motionHint {
            prompt += "\n\nAn automatic motion sensor measured the hand movement in this clip as: \(motionHint.rawValue.uppercased()). Treat HIGH as shaking/flapping present and LOW as steady; make your summary consistent with this."
        }

        let output = try await session.respond(
            to: prompt,
            video: frames.isEmpty ? nil : .frames(frames)
        )

        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw VLMServiceError.emptyOutput }
        return trimmed
    }
}
