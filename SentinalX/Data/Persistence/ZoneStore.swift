//
//  ZoneStore.swift
//  SentinalX
//

import Foundation
import SwiftData

/// SwiftData boundary for zones. Callers pass snapshots in and get snapshots
/// back, so the screen never depends on `@Model` types.
@MainActor
final class ZoneStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func load() throws -> [ZoneSnapshot] {
        let descriptor = FetchDescriptor<ZoneRecord>(
            sortBy: [SortDescriptor(\.sortIndex)]
        )
        return try context.fetch(descriptor).map(\.snapshot)
    }

    /// Inserts the demo layout the first time the store is empty.
    @discardableResult
    func seedIfNeeded() throws -> Bool {
        let count = try context.fetchCount(FetchDescriptor<ZoneRecord>())
        guard count == 0 else { return false }
        for zone in DemoCatalog.zones() {
            context.insert(ZoneRecord(snapshot: zone))
        }
        try context.save()
        return true
    }

    func save(_ snapshots: [ZoneSnapshot]) throws {
        let existing = try context.fetch(FetchDescriptor<ZoneRecord>())
        let byID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        for snapshot in snapshots {
            if let record = byID[snapshot.id] {
                record.apply(snapshot)
            } else {
                context.insert(ZoneRecord(snapshot: snapshot))
            }
        }
        let kept = Set(snapshots.map(\.id))
        for record in existing where !kept.contains(record.id) {
            context.delete(record)
        }
        try context.save()
    }

    func resetToDemo() throws {
        try context.delete(model: ZoneRecord.self)
        for zone in DemoCatalog.zones() {
            context.insert(ZoneRecord(snapshot: zone))
        }
        try context.save()
    }
}
