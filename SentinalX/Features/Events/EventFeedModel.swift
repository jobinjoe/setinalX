//
//  EventFeedModel.swift
//  SentinalX
//

import Foundation
import Observation

enum FeedLink: Equatable {
    case paused
    case checking
    case live
    case offline
}

/// Polls the mock API and folds new posts into the on-device log.
@MainActor
@Observable
final class EventFeedModel {
    private(set) var link: FeedLink = .checking
    private(set) var isPulling = false

    private let log: EventLog
    private let client: any EventFeedClient
    private let zones: ZoneBoardModel
    private let session: SessionStore
    private var pullInFlight = false

    init(
        log: EventLog,
        client: any EventFeedClient,
        zones: ZoneBoardModel,
        session: SessionStore
    ) {
        self.log = log
        self.client = client
        self.zones = zones
        self.session = session
    }

    /// Keeps polling until the view's task is cancelled.
    func run() async {
        guard session.liveFeedEnabled else {
            link = .paused
            return
        }
        await pull()
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(session.pollSeconds))
            if Task.isCancelled { break }
            guard session.liveFeedEnabled else { continue }
            await pull()
        }
    }

    func refreshNow() async {
        await pull()
    }

    func clearAndRefresh() async {
        do {
            try log.clear()
            session.feedCursor = 0
        } catch {
            link = .offline
            return
        }
        guard session.liveFeedEnabled else {
            link = .paused
            return
        }
        await pull()
    }

    private func pull() async {
        guard !pullInFlight else { return }
        pullInFlight = true
        isPulling = true
        defer {
            pullInFlight = false
            isPulling = false
        }
        if link != .live {
            link = .checking
        }

        do {
            let posts = try await nextPage()
            let names = zones.zones.map(\.name)
            let zoneNames = names.isEmpty ? ["System"] : names
            let known = Set(log.events.compactMap(\.remoteID))
            let fresh = posts.compactMap { post -> SecurityEvent? in
                guard !known.contains(post.id) else { return nil }
                return map(post, zoneNames: zoneNames)
            }
            for event in fresh {
                if Task.isCancelled { return }
                try log.ingestRemote(event)
                try await Task.sleep(for: .milliseconds(140))
            }
            link = .live
        } catch is CancellationError {
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch {
            if !Task.isCancelled {
                link = .offline
            }
        }
    }

    private func nextPage() async throws -> [RemotePost] {
        var origin = min(max(session.feedCursor, 0), 96)
        var posts = try await client.fetchBatch(startingAt: origin, limit: 4)
        if posts.isEmpty, origin != 0 {
            origin = 0
            posts = try await client.fetchBatch(startingAt: 0, limit: 4)
        }
        let next = origin + posts.count
        session.feedCursor = next >= 100 || posts.isEmpty ? 0 : next
        return posts
    }

    private func map(_ post: RemotePost, zoneNames: [String]) -> SecurityEvent {
        let index = abs(post.userId) % zoneNames.count
        return SecurityEvent(
            id: UUID(),
            remoteID: post.id,
            title: sentence(post.title),
            detail: sentence(post.body),
            severity: severity(for: post.id),
            zoneName: zoneNames[index],
            occurredAt: Date().addingTimeInterval(-Double((post.id % 8) * 40)),
            source: .cloud
        )
    }

    private func severity(for id: Int) -> EventSeverity {
        switch id % 10 {
        case 0: .critical
        case 1, 2: .warning
        case 3, 4: .notice
        default: .info
        }
    }

    private func sentence(_ text: String) -> String {
        let trimmed = text
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return "Cloud event" }
        return first.uppercased() + trimmed.dropFirst()
    }
}
