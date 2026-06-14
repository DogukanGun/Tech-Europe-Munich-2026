import Foundation

/// Parsed, conservative interpretation of the model's JSON output.
///
/// The model only ever reports *observed motion*; the safety-relevant mapping
/// to user-facing copy lives in `outcome` and in `ResultView`. Nothing here
/// asserts a diagnosis.
struct AsterixisResult: Sendable, Equatable {

    enum Pattern: String, Sendable { case irregular, rhythmic, none, voluntary, unknown }
    enum Symmetry: String, Sendable { case asynchronous, synchronous, na, unknown }
    enum Confidence: String, Sendable { case low, medium, high, unknown }
    enum Decision: String, Sendable { case flap, noFlap = "no_flap", inconclusive, unknown }

    var postureValid: Bool
    var flapEvents: Int
    var pattern: Pattern
    var symmetry: Symmetry
    var confidence: Confidence
    /// The model's own cautious assessment of the motion.
    var decision: Decision
    /// The model's plain-language summary (shown to the user).
    var summary: String
    var note: String

    /// What the app should tell the user. Deliberately limited to three safe states.
    enum Outcome { case invalidPosture, flapDetected, noFlap }

    /// Lets the measured pixel-motion override the model's shaking/steady call,
    /// which the VLM judges unreliably from still frames.
    mutating func applyMotion(_ level: MotionLevel) {
        switch level {
        case .high:
            decision = .flap
            if pattern == .none || pattern == .unknown { pattern = .irregular }
            if flapEvents == 0 { flapEvents = 2 }
        case .low:
            decision = .noFlap
            if pattern == .irregular { pattern = .none }
        case .medium:
            break  // ambiguous — trust the model's own decision
        }
    }

    /// Stable string for the outcome, used when persisting/sending the result.
    var outcomeKey: String {
        switch outcome {
        case .invalidPosture: return "couldnt_perform"
        case .flapDetected: return "flap_detected"
        case .noFlap: return "no_flap"
        }
    }

    var outcome: Outcome {
        // Driven primarily by the model's own decision so a real attempt (shaking or
        // steady) isn't dumped into "couldn't perform". Only fall back to "invalid"
        // when the model truly couldn't see a hand.
        if decision == .flap || (flapEvents > 0 && pattern == .irregular) {
            return .flapDetected
        }
        if decision == .noFlap || pattern == .none || pattern == .rhythmic || pattern == .voluntary {
            return .noFlap
        }
        // decision is inconclusive/unknown with no clear motion signal
        return postureValid ? .noFlap : .invalidPosture
    }
}

extension AsterixisResult {

    /// Lenient decoder for raw model text. LLM output varies (code fences, stray
    /// prose, string-vs-number), so we extract the JSON object substring and map
    /// fields with safe fallbacks rather than failing hard.
    static func parse(from raw: String) -> AsterixisResult? {
        guard let json = extractJSONObject(from: raw),
              let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        let posture = boolValue(obj["postureValid"]) ?? false
        let flaps = intValue(obj["flapEvents"]) ?? 0
        let pattern = Pattern(rawValue: stringValue(obj["pattern"]).lowercased()) ?? .unknown
        let symmetryRaw = stringValue(obj["symmetry"]).lowercased().replacingOccurrences(of: "/", with: "")
        let symmetry = Symmetry(rawValue: symmetryRaw) ?? .unknown
        let confidence = Confidence(rawValue: stringValue(obj["confidence"]).lowercased()) ?? .unknown
        let decisionRaw = stringValue(obj["decision"]).lowercased()
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "_")
        let decision = Decision(rawValue: decisionRaw) ?? .unknown
        let summary = stringValue(obj["summary"])
        let note = stringValue(obj["note"])

        return AsterixisResult(
            postureValid: posture,
            flapEvents: max(0, flaps),
            pattern: pattern,
            symmetry: symmetry,
            confidence: confidence,
            decision: decision,
            summary: summary,
            note: note
        )
    }

    /// Grabs the first balanced-looking `{ ... }` block from arbitrary text.
    private static func extractJSONObject(from raw: String) -> String? {
        guard let start = raw.firstIndex(of: "{"),
              let end = raw.lastIndex(of: "}"),
              start < end
        else { return nil }
        return String(raw[start...end])
    }

    private static func boolValue(_ any: Any?) -> Bool? {
        switch any {
        case let b as Bool: return b
        case let n as NSNumber: return n.boolValue
        case let s as String:
            switch s.lowercased() {
            case "true", "yes", "1": return true
            case "false", "no", "0": return false
            default: return nil
            }
        default: return nil
        }
    }

    private static func intValue(_ any: Any?) -> Int? {
        switch any {
        case let n as NSNumber: return n.intValue
        case let i as Int: return i
        case let s as String: return Int(s.trimmingCharacters(in: .whitespaces))
        default: return nil
        }
    }

    private static func stringValue(_ any: Any?) -> String {
        switch any {
        case let s as String: return s
        case let n as NSNumber: return n.stringValue
        default: return ""
        }
    }
}
