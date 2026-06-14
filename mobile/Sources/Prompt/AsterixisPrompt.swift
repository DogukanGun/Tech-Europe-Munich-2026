import Foundation

/// The instruction sent to the on-device vision model along with the sampled
/// video frames. The model reports observed motion, makes a cautious assessment,
/// and writes a short plain-language summary — but is told never to state a
/// diagnosis. The app applies its own conservative gating on top.
enum AsterixisPrompt {
    static let text = """
    You are analyzing a short video, given as a time-ordered sequence of frames, \
    of a person holding BOTH hands out toward the camera to test for "asterixis" \
    (a flapping / shaking hand movement, also called a liver flap). They were asked \
    to extend both arms forward, bend the wrists back (palms toward the camera, \
    fingers spread), and hold still for about 30 seconds.

    Watch the WHOLE sequence across time and focus on SHAKING or FLAPPING of the \
    held hands. Report ONLY what you observe about the motion. Do NOT name or imply \
    any disease.

    A "flap event" is a brief, sudden DOWNWARD flexion (a drop) of the hand/wrist \
    that interrupts the held posture and then returns. Asterixis flaps are IRREGULAR \
    (arrhythmic) and the two hands often flap out of sync. A smooth, rhythmic \
    oscillation is a tremor, not a flap. Deliberate repositioning is "voluntary".

    Be LENIENT about posture: set "postureValid": true whenever at least one hand is \
    visible and roughly held out for most of the clip — do NOT require a perfect wrist \
    angle. Choose "decision": "flap" if you see any shaking/flapping, "no_flap" if the \
    hand(s) are held steady, and only "inconclusive" if you genuinely cannot see a \
    hand at all.

    Respond with ONLY a single JSON object — no prose, no markdown fences — with \
    exactly these fields:
    {
      "postureValid": true | false,          // true if a hand is visible and roughly held out for most of the clip
      "flapEvents": <integer>,                // count of brief sudden downward wrist flexions that return to posture
      "pattern": "irregular" | "rhythmic" | "none" | "voluntary",
      "symmetry": "asynchronous" | "synchronous" | "n/a",
      "confidence": "low" | "medium" | "high",
      "decision": "flap" | "no_flap" | "inconclusive",   // your assessment: flap if any shaking, no_flap if steady, inconclusive only if no hand visible
      "summary": "<2-3 plain-language sentences describing what the hands did, whether a flapping/shaking pattern was present, and what limited the read (lighting, blur, framing). Do NOT mention any disease.>",
      "note": "<one short sentence on what most limited the read>"
    }
    """
}
