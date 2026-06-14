import AVFoundation
import CoreImage
import MLXLMCommon

/// Samples evenly-spaced frames from a recorded clip and returns them as
/// `UserInput.VideoFrame`s (a CIImage + timestamp) for the VLM's native
/// video-frames input. Frames are downscaled via `maximumSize` to keep the
/// image-token budget — and on-device memory — small.
enum FrameSampler {

    static func sampleVideoFrames(
        url: URL,
        count: Int = 12,
        maxDimension: CGFloat = 512
    ) async throws -> [UserInput.VideoFrame] {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let seconds = CMTimeGetSeconds(duration)
        guard seconds.isFinite, seconds > 0 else { return [] }

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        generator.maximumSize = CGSize(width: maxDimension, height: maxDimension)

        let n = max(count, 1)
        var frames: [UserInput.VideoFrame] = []
        frames.reserveCapacity(n)

        for i in 0..<n {
            // Spread samples across the clip, nudged slightly inside the ends
            // to avoid black/garbage edge frames.
            let fraction = n == 1 ? 0.5 : Double(i) / Double(n - 1)
            let t = min(max(seconds * fraction, 0.05), seconds - 0.05)
            let requested = CMTime(seconds: t, preferredTimescale: 600)
            do {
                let (cgImage, actualTime) = try await generator.image(at: requested)
                frames.append(.init(frame: CIImage(cgImage: cgImage), timeStamp: actualTime))
            } catch {
                // Skip individual frames that fail to extract rather than aborting.
                continue
            }
        }
        return frames
    }
}
