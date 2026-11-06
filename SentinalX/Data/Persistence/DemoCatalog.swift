//
//  DemoCatalog.swift
//  SentinalX
//

import Foundation

/// The six zones a fresh install starts with.
///
/// The mix is a Home posture with two zones that cannot arm: the kitchen
/// window is under the battery floor, and the back gate is open. That gives
/// the arming rules something visible to refuse.
nonisolated enum DemoCatalog {
    static let frontDoorID = stableID(1)
    static let garageID = stableID(2)
    static let kitchenID = stableID(3)
    static let gateID = stableID(4)
    static let livingRoomID = stableID(5)
    static let hallwayID = stableID(6)

    static func zones(now: Date = .now) -> [ZoneSnapshot] {
        [
            ZoneSnapshot(
                id: frontDoorID,
                name: "Front Door",
                kind: .door,
                role: .entry,
                isArmed: true,
                batteryPercent: 92,
                signalStrength: 90,
                temperatureCelsius: 21.4,
                lastHeartbeat: now.addingTimeInterval(-120),
                sortIndex: 0
            ),
            ZoneSnapshot(
                id: garageID,
                name: "Garage Entry",
                kind: .door,
                role: .entry,
                isArmed: true,
                batteryPercent: 64,
                signalStrength: 74,
                temperatureCelsius: 18.2,
                lastHeartbeat: now.addingTimeInterval(-360),
                sortIndex: 1
            ),
            ZoneSnapshot(
                id: kitchenID,
                name: "Kitchen Window",
                kind: .window,
                role: .perimeter,
                isArmed: false,
                batteryPercent: 18,
                signalStrength: 66,
                temperatureCelsius: 22.0,
                lastHeartbeat: now.addingTimeInterval(-840),
                sortIndex: 2
            ),
            ZoneSnapshot(
                id: gateID,
                name: "Back Gate",
                kind: .gate,
                role: .perimeter,
                isArmed: false,
                batteryPercent: 77,
                isContactOpen: true,
                signalStrength: 58,
                temperatureCelsius: 19.5,
                lastHeartbeat: now.addingTimeInterval(-240),
                sortIndex: 3
            ),
            ZoneSnapshot(
                id: livingRoomID,
                name: "Living Room",
                kind: .motion,
                role: .interior,
                isArmed: false,
                batteryPercent: 81,
                motionLevel: 12,
                signalStrength: 94,
                temperatureCelsius: 22.8,
                lastHeartbeat: now.addingTimeInterval(-45),
                sortIndex: 4
            ),
            ZoneSnapshot(
                id: hallwayID,
                name: "Hallway",
                kind: .motion,
                role: .interior,
                isArmed: false,
                batteryPercent: 55,
                motionLevel: 4,
                signalStrength: 86,
                temperatureCelsius: 22.1,
                lastHeartbeat: now.addingTimeInterval(-540),
                sortIndex: 5
            )
        ]
    }

    static func welcomeEvent(now: Date = .now) -> SecurityEvent {
        SecurityEvent(
            id: UUID(),
            remoteID: nil,
            title: "Panel online",
            detail: "Local monitoring is ready. Cloud events arrive as the live feed checks in.",
            severity: .info,
            zoneName: "All zones",
            occurredAt: now,
            source: .panel
        )
    }

    private static func stableID(_ n: Int) -> UUID {
        let value = String(format: "00000000-0000-4000-8000-%012X", n)
        guard let id = UUID(uuidString: value) else {
            fatalError("Demo zone id \(n) is not a UUID.")
        }
        return id
    }
}
