import Foundation

/// Best-effort persistence of a result to your backend (which writes it to the
/// MongoDB "MobileRes" collection). Sends only the structured result — no raw
/// video or frames ever leave the device.
enum ResultStore {
    @discardableResult
    static func save(_ result: AsterixisResult) async -> Bool {
        guard BackendConfig.isConfigured,
              let url = URL(string: BackendConfig.resultEndpoint)
        else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !BackendConfig.apiKey.isEmpty {
            request.setValue(BackendConfig.apiKey, forHTTPHeaderField: "x-api-key")
        }

        let payload: [String: Any] = [
            "outcome": result.outcomeKey,
            "decision": result.decision.rawValue,
            "flapEvents": result.flapEvents,
            "pattern": result.pattern.rawValue,
            "symmetry": result.symmetry.rawValue,
            "confidence": result.confidence.rawValue,
            "postureValid": result.postureValid,
            "summary": result.summary,
            "note": result.note,
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse).map { (200..<300).contains($0.statusCode) } ?? false
        } catch {
            return false
        }
    }
}
