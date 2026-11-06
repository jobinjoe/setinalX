//
//  JSONPlaceholderClient.swift
//  SentinalX
//

import Foundation

nonisolated struct RemotePost: Decodable, Equatable, Sendable {
    var id: Int
    var userId: Int
    var title: String
    var body: String
}

nonisolated enum EventFeedError: Error {
    case badURL
    case badResponse
    case badPayload
}

/// The one network seam. The feed model asks for a page; it does not know
/// which host it came from.
nonisolated protocol EventFeedClient: Sendable {
    func fetchBatch(startingAt start: Int, limit: Int) async throws -> [RemotePost]
}

/// Free mock API: https://jsonplaceholder.typicode.com/posts
/// `_start` and `_limit` page through the 100 posts so each poll can surface
/// posts the log has not stored yet.
nonisolated struct JSONPlaceholderClient: EventFeedClient {
    var session: URLSession = .shared

    func fetchBatch(startingAt start: Int, limit: Int) async throws -> [RemotePost] {
        guard var components = URLComponents(string: "https://jsonplaceholder.typicode.com/posts") else {
            throw EventFeedError.badURL
        }
        components.queryItems = [
            URLQueryItem(name: "_start", value: String(start)),
            URLQueryItem(name: "_limit", value: String(limit))
        ]
        guard let url = components.url else { throw EventFeedError.badURL }

        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw EventFeedError.badResponse
        }
        do {
            return try JSONDecoder().decode([RemotePost].self, from: data)
        } catch {
            throw EventFeedError.badPayload
        }
    }
}

/// Fixed pages for previews, so the canvas does not depend on the network.
nonisolated struct PreviewEventClient: EventFeedClient {
    func fetchBatch(startingAt start: Int, limit: Int) async throws -> [RemotePost] {
        try await Task.sleep(for: .milliseconds(250))
        guard start < 8 else { return [] }
        return (0..<limit).map { offset in
            let id = start + offset + 1
            return RemotePost(
                id: id,
                userId: id,
                title: "preview signal \(id) checked in",
                body: "Preview data standing in for the live service."
            )
        }
    }
}
