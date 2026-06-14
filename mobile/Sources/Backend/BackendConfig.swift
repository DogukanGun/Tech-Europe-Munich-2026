import Foundation

/// Endpoint of YOUR backend that stores results in MongoDB (collection "MobileRes").
///
/// IMPORTANT: the MongoDB connection string must live ON THE BACKEND as an
/// environment variable — never in this app. A connection string embedded in the
/// iOS binary can be extracted and gives full read/write to your database.
///
/// Set this to your deployed endpoint, e.g. https://your-app.vercel.app/api/save-result
enum BackendConfig {
    static let resultEndpoint = "https://backend-two-zeta-83.vercel.app/api/save-result"

    /// Must match the backend's API_KEY env var. Leave empty if the backend has none.
    ///
    /// SECURITY: never hardcode the real key here — it gets baked into the app
    /// binary and committed to git, where it can be extracted. Inject it at build
    /// time instead (e.g. an xcconfig-driven Info.plist value read via Bundle).
    /// TODO: wire up build-time injection and set this to the injected value.
    /// NOTE: the previously committed key is exposed in git history and MUST be
    /// rotated/invalidated on the backend (Vercel `API_KEY` env var).
    static let apiKey = ""

    static var isConfigured: Bool {
        !resultEndpoint.isEmpty && !resultEndpoint.contains("PUT_")
    }
}
