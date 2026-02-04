import Foundation

struct SyncSettings {
    var serverURL: URL
    var token: String
    var mode: String
}

struct SyncClient {
    func sync(payload: SyncRequestPayload, settings: SyncSettings) async throws -> SyncResponsePayload {
        var request = URLRequest(url: settings.serverURL.appendingPathComponent("/v1/sync"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !settings.token.isEmpty {
            request.setValue("Bearer \(settings.token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder.iso8601.encode(payload)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder.iso8601.decode(SyncResponsePayload.self, from: data)
    }
}
