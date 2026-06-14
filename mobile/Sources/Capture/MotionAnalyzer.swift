import AVFoundation
import CoreGraphics

enum MotionLevel: String, Sendable { case low, medium, high }

/// Measures how much the hands actually moved by comparing consecutive frames
/// (mean absolute pixel difference on small grayscale thumbnails). This is far
/// more reliable than asking a small VLM to infer motion from still frames, so
/// it drives the shaking/flap decision; the VLM is kept for the summary.
enum MotionAnalyzer {

    // Tunable thresholds (normalized 0...1 mean per-pixel diff between frames).
    // Logged to the console so they can be calibrated on a real device.
    private static let highThreshold = 0.040
    private static let lowThreshold = 0.015

    static func analyze(url: URL, sampleCount: Int = 20) async -> (level: MotionLevel, score: Double) {
        let asset = AVURLAsset(url: url)
        guard let duration = try? await asset.load(.duration) else { return (.medium, 0) }
        let seconds = CMTimeGetSeconds(duration)
        guard seconds.isFinite, seconds > 0 else { return (.medium, 0) }

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        generator.maximumSize = CGSize(width: 96, height: 96)

        let side = 48
        let n = max(sampleCount, 2)
        var frames: [[UInt8]] = []
        frames.reserveCapacity(n)

        for i in 0..<n {
            let t = seconds * Double(i) / Double(n - 1)
            let time = CMTime(seconds: min(max(t, 0.02), seconds - 0.02), preferredTimescale: 600)
            guard let (cgImage, _) = try? await generator.image(at: time),
                  let bytes = grayscaleBytes(cgImage, side: side)
            else { continue }
            frames.append(bytes)
        }
        guard frames.count >= 2 else { return (.medium, 0) }

        var diffs: [Double] = []
        for k in 1..<frames.count {
            let a = frames[k - 1], b = frames[k]
            let count = min(a.count, b.count)
            guard count > 0 else { continue }
            var sum = 0
            for j in 0..<count { sum += abs(Int(a[j]) - Int(b[j])) }
            diffs.append(Double(sum) / Double(count) / 255.0)
        }
        guard !diffs.isEmpty else { return (.medium, 0) }

        let mean = diffs.reduce(0, +) / Double(diffs.count)
        let level: MotionLevel
        if mean > highThreshold { level = .high }
        else if mean < lowThreshold { level = .low }
        else { level = .medium }

        print("[MotionAnalyzer] meanDiff=\(mean) level=\(level.rawValue) frames=\(frames.count)")
        return (level, mean)
    }

    /// Renders a CGImage into a small 8-bit grayscale buffer and returns its bytes.
    private static func grayscaleBytes(_ image: CGImage, side: Int) -> [UInt8]? {
        let count = side * side
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        defer { buffer.deallocate() }
        buffer.initialize(repeating: 0, count: count)

        guard let ctx = CGContext(
            data: buffer,
            width: side, height: side,
            bitsPerComponent: 8, bytesPerRow: side,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }

        ctx.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
        return Array(UnsafeBufferPointer(start: buffer, count: count))
    }
}
