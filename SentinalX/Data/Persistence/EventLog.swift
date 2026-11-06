//
//  EventLog.swift
//  SentinalX
//

import Foundation
import Observation
import SwiftData

/// On-device activity log. Panel actions and cloud posts share one list.
@MainActor
@Observable
final class EventLog {
    private(set) var events: [SecurityEvent] = []
    private let context: ModelContext
    private let remoteCap = 60

    init(context: ModelContext) {
        self.context = context
    }

    func reload() throws {
        let descriptor = FetchDescriptor<EventRecord>(
            sortBy: [SortDescriptor(\.occurredAt, order: .reverse)]
        )
        events = try context.fetch(descriptor).map(\.event)
    }

    func append(_ event: SecurityEvent) throws {
        context.insert(EventRecord(event: event))
        try context.save()
        events.insert(event, at: 0)
        events.sort { $0.occurredAt > $1.occurredAt }
    }

    func ingestRemote(_ event: SecurityEvent) throws {
        guard let remoteID = event.remoteID else { return }
        if events.contains(where: { $0.remoteID == remoteID }) { return }
        try append(event)
        try trimRemote()
    }

    func clear() throws {
        try context.delete(model: EventRecord.self)
        try context.save()
        events = []
    }

    private func trimRemote() throws {
        let remote = events.filter { $0.source == .cloud }
        guard remote.count > remoteCap else { return }
        let overflow = remote
            .sorted { $0.occurredAt < $1.occurredAt }
            .prefix(remote.count - remoteCap)
        let dropIDs = Set(overflow.map(\.id))
        let stored = try context.fetch(FetchDescriptor<EventRecord>())
        for record in stored where dropIDs.contains(record.id) {
            context.delete(record)
        }
        try context.save()
        events.removeAll { dropIDs.contains($0.id) }
    }
}
