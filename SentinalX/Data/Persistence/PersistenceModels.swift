//
//  PersistenceModels.swift
//  SentinalX
//

import Foundation
import SwiftData

@Model
final class ZoneRecord {
    var id: UUID
    var name: String
    var kindRaw: String
    var roleRaw: String
    var isArmed: Bool
    var batteryPercent: Int
    var isContactOpen: Bool
    var motionLevel: Int
    var isTampered: Bool
    var isOnline: Bool
    var signalStrength: Int
    var temperatureCelsius: Double
    var lastHeartbeat: Date
    var sortIndex: Int

    init(snapshot: ZoneSnapshot) {
        self.id = snapshot.id
        self.name = snapshot.name
        self.kindRaw = snapshot.kind.rawValue
        self.roleRaw = snapshot.role.rawValue
        self.isArmed = snapshot.isArmed
        self.batteryPercent = snapshot.batteryPercent
        self.isContactOpen = snapshot.isContactOpen
        self.motionLevel = snapshot.motionLevel
        self.isTampered = snapshot.isTampered
        self.isOnline = snapshot.isOnline
        self.signalStrength = snapshot.signalStrength
        self.temperatureCelsius = snapshot.temperatureCelsius
        self.lastHeartbeat = snapshot.lastHeartbeat
        self.sortIndex = snapshot.sortIndex
    }

    func apply(_ snapshot: ZoneSnapshot) {
        name = snapshot.name
        kindRaw = snapshot.kind.rawValue
        roleRaw = snapshot.role.rawValue
        isArmed = snapshot.isArmed
        batteryPercent = snapshot.batteryPercent
        isContactOpen = snapshot.isContactOpen
        motionLevel = snapshot.motionLevel
        isTampered = snapshot.isTampered
        isOnline = snapshot.isOnline
        signalStrength = snapshot.signalStrength
        temperatureCelsius = snapshot.temperatureCelsius
        lastHeartbeat = snapshot.lastHeartbeat
        sortIndex = snapshot.sortIndex
    }

    var snapshot: ZoneSnapshot {
        ZoneSnapshot(
            id: id,
            name: name,
            kind: ZoneKind(rawValue: kindRaw) ?? .door,
            role: ZoneRole(rawValue: roleRaw) ?? .entry,
            isArmed: isArmed,
            batteryPercent: batteryPercent,
            isContactOpen: isContactOpen,
            motionLevel: motionLevel,
            isTampered: isTampered,
            isOnline: isOnline,
            signalStrength: signalStrength,
            temperatureCelsius: temperatureCelsius,
            lastHeartbeat: lastHeartbeat,
            sortIndex: sortIndex
        )
    }
}

@Model
final class EventRecord {
    var id: UUID
    var remoteID: Int?
    var title: String
    var detail: String
    var severityRaw: String
    var zoneName: String
    var occurredAt: Date
    var sourceRaw: String

    init(event: SecurityEvent) {
        self.id = event.id
        self.remoteID = event.remoteID
        self.title = event.title
        self.detail = event.detail
        self.severityRaw = event.severity.rawValue
        self.zoneName = event.zoneName
        self.occurredAt = event.occurredAt
        self.sourceRaw = event.source.rawValue
    }

    var event: SecurityEvent {
        SecurityEvent(
            id: id,
            remoteID: remoteID,
            title: title,
            detail: detail,
            severity: EventSeverity(rawValue: severityRaw) ?? .info,
            zoneName: zoneName,
            occurredAt: occurredAt,
            source: EventSource(rawValue: sourceRaw) ?? .panel
        )
    }
}
