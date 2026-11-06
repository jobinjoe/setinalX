//
//  SecurityEvent.swift
//  SentinalX
//

import Foundation

nonisolated enum EventSeverity: String, CaseIterable, Equatable, Sendable {
    case info
    case notice
    case warning
    case critical
}

nonisolated enum EventSource: String, CaseIterable, Equatable, Sendable {
    /// Produced on device when somebody arms, disarms, or restores the demo.
    case panel
    /// Produced from the remote mock feed.
    case cloud
}

nonisolated struct SecurityEvent: Equatable, Identifiable, Sendable {
    var id: UUID
    var remoteID: Int?
    var title: String
    var detail: String
    var severity: EventSeverity
    var zoneName: String
    var occurredAt: Date
    var source: EventSource
}
