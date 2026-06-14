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
    static let apiKey = "0978d97e2677b32c805dac790efcd8ea2cb328b8e7683e72"

    static var isConfigured: Bool {
        !resultEndpoint.isEmpty && !resultEndpoint.contains("PUT_")
    }
}
