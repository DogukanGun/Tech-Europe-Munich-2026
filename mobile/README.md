# Liver Flap Check

A single-purpose iOS app that uses an **on-device** vision-language model (Gemma 4
E2B, 4-bit, via MLX) to watch a short clip of a person's hands and report whether
it sees **asterixis** — the irregular "liver flap" associated with hepatic
encephalopathy.

> ⚠️ **Educational / awareness only. This is NOT a medical device and does NOT
> diagnose any disease.** A flapping pattern (asterixis) can occur in several
> serious conditions — advanced liver disease, but also kidney failure, CO₂
> retention, and some medications — so it is a reason to *see a doctor*, never a
> diagnosis. A "no flap" result rules nothing out. See `Sources/Views/DisclaimerView.swift`.

## Why asterixis (and not the PDF "hand test")

The source PDF (*Global burden of liver disease: 2023 update*) is an epidemiology
review and contains **no hand-sign exam test**. The clinically real, *video-dependent*
hand sign for liver disease is **asterixis**: arms extended, wrists dorsiflexed,
fingers spread, held ~30 s — a positive sign is a sudden, irregular, asynchronous
flap. It needs video because the sign *is* motion over time, which a still frame
cannot capture.

## How it works

```
Disclaimer/consent → (first launch) model download → instructions
   → record ~30 s clip → sample ~10 frames → on-device VLM → safe-gated result
```

- **Capture** — `AVCaptureSession` records to a temp file; `AVAssetImageGenerator`
  samples ~10 downscaled frames (`Sources/Capture/`).
- **Model** — `GemmaVLMService` loads `VLMRegistry.gemma4_E2B_it_4bit` via the
  `#huggingFaceLoadModelContainer` macro (mlx-swift-lm is HF-client-agnostic, so
  the app supplies the Hugging Face client + tokenizer through **swift-transformers**
  and **swift-huggingface**), then runs `ChatSession.respond(to:video:)` over the
  frames using MLX's native video-frames input. All inference is on-device; nothing
  is uploaded (`Sources/Model/`).
- **Prompt** — constrains the model to *describing observed motion only* and
  forbids diagnosis (`Sources/Prompt/AsterixisPrompt.swift`).
- **Result gating** — the app (not the model) maps the JSON to one of three safe
  states: *couldn't perform*, *flap seen → see a doctor*, *no flap → rules nothing
  out* (`Sources/Model/AsterixisResult.swift`, `Sources/Views/ResultView.swift`).

## Requirements

- **A current Xcode** (see *Toolchain note* below).
- A **physical Apple-Silicon iPhone** (A16/A17/A18, ideally 8 GB RAM). The camera
  and MLX Metal inference do not work in the Simulator.
- An Apple Developer account for device signing; the paid program ($99/yr) for
  TestFlight.
- ~2 GB free space + Wi-Fi for the first-run model download.

## Build & run

```bash
brew install xcodegen          # if not installed
xcodegen generate              # creates HealthChecker.xcodeproj from project.yml
open HealthChecker.xcodeproj
```

In Xcode: select the **HealthChecker** target → *Signing & Capabilities* → set your
**Team** (or edit `DEVELOPMENT_TEAM` in `project.yml` and re-run `xcodegen generate`)
→ choose your connected iPhone → **Run**.

First launch downloads the Gemma 4 E2B weights (~2 GB) from Hugging Face into the
app container and caches them; later launches skip the download.

### Memory entitlement
`Support/HealthChecker.entitlements` requests
`com.apple.developer.kernel.increased-memory-limit` so the model has RAM headroom.
If your provisioning profile doesn't grant it, remove that key.

## Toolchain note (important)

`mlx-swift-lm` 3.31.3 declares `swift-tools-version: 6.1` and is written for a
current SDK in which `CIContext` is `Sendable`. On **older Xcode (16.x)** the SDK's
`CIContext` is *not* `Sendable`, so one line in the dependency
(`Libraries/MLXVLM/MediaProcessing.swift`: `private let context = CIContext()`)
trips Swift 6 strict-concurrency and the build fails. The app's own code is
unaffected.

**Fix options:**
1. **On Xcode 16.x** (verified — this repo builds green this way), run the helper
   after package resolution to mark that thread-safe global `nonisolated(unsafe)`:
   ```bash
   xcodegen generate
   xcodebuild -resolvePackageDependencies -project HealthChecker.xcodeproj -scheme HealthChecker
   ./scripts/fix-mlx-concurrency.sh
   ```
   `CIContext` is documented thread-safe, so this is correct. Note: the patch lives
   in the resolved package checkout and is lost if you "Reset Package Caches" /
   re-resolve — just re-run the script (it's idempotent and self-repairing).
2. **Use a current Xcode** — the dependency should compile unchanged (CIContext is
   `Sendable` in newer SDKs), making the patch unnecessary.

> Verified: `xcodebuild` for `generic/platform=iOS` reports **BUILD SUCCEEDED** with
> zero errors/warnings in the app sources on Xcode 16.3 after running the helper.
> This confirms compilation/linking; on-device runtime (model download + inference)
> still needs a real iPhone.

## Verification checklist

1. Build to a physical iPhone.
2. First launch: model downloads with progress; second launch skips it.
3. **Model sanity** — confirm coherent JSON before trusting the flow (try a still
   clip vs. a deliberately wobbling-hand clip).
4. Still hands → `flapEvents: 0` / `pattern: none` → "no pattern seen, does not rule
   anything out."
5. Deliberate irregular flapping → `flapEvents > 0` → "see a doctor" triage copy.
   (Pipeline check, *not* clinical validation.)
6. Disclaimer gate appears first run; result copy never asserts a diagnosis.

## Model alternatives

`GemmaVLMService.configuration` can be swapped to `.gemma4_E4B_it_4bit` (better,
~4 GB) or `.gemma3_4B_qat_4bit` (most battle-tested MLX vision) if E2B output is
poor on your device.

## License / data

- **Gemma 4** is Apache 2.0 (clean for distribution).
- Video and frames stay on-device and are never uploaded. **Exception:** each
  result's text fields (outcome, decision, summary, etc.) are POSTed to your backend
  (`Sources/Backend/`), which stores them in MongoDB `MobileRes`. No imagery leaves
  the device. The MongoDB connection string lives server-side only (see `backend/`).
- This app makes **no medical claim**. Do not market it as detecting, screening for,
  or diagnosing disease (that would likely make it a regulated medical device under
  FDA / EU MDR).
