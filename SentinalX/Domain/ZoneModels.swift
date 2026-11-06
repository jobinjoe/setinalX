//
//  ZoneModels.swift
//  SentinalX
//

import Foundation

/// Product rule shared by the arming policy and the zone screen, so a
/// warning on screen and a refused arm always mean the same thing.
nonisolated enum ZoneRules {
    static let minimumBatteryPercent = 20
}

nonisolated enum ZoneKind: String, CaseIterable, Sendable {
    case door
    case window
    case gate
    case motion
    case glass

    /// Contact, gate, and glass sensors can be "open" in a way that must
    /// block arming. Motion is an activity level, not a contact.
    var hasContact: Bool {
        switch self {
        case .door, .window, .gate, .glass:
            true
        case .motion:
            false
        }
    }
}

nonisolated enum ZoneRole: String, CaseIterable, Sendable {
    /// Doors you walk through. Armed in Home and Away.
    case entry
    /// Windows, gates, and other shell sensors. Armed in Home and Away.
    case perimeter
    /// Motion inside the building. Armed only in Away.
    case interior
}

nonisolated enum ZoneFault: String, CaseIterable, Hashable, Sendable {
    case offline
    case tamper
    case contactOpen
    case lowBattery
}

/// A zone as the rest of the app sees it. Persistence and the screen both
/// convert to and from this value. Arming never touches the database itself.
nonisolated struct ZoneSnapshot: Equatable, Identifiable, Sendable {
    var id: UUID
    var name: String
    var kind: ZoneKind
    var role: ZoneRole
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

    init(
        id: UUID,
        name: String,
        kind: ZoneKind,
        role: ZoneRole,
        isArmed: Bool = false,
        batteryPercent: Int = 100,
        isContactOpen: Bool = false,
        motionLevel: Int = 0,
        isTampered: Bool = false,
        isOnline: Bool = true,
        signalStrength: Int = 80,
        temperatureCelsius: Double = 21,
        lastHeartbeat: Date = .now,
        sortIndex: Int = 0
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.role = role
        self.isArmed = isArmed
        self.batteryPercent = batteryPercent
        self.isContactOpen = isContactOpen
        self.motionLevel = motionLevel
        self.isTampered = isTampered
        self.isOnline = isOnline
        self.signalStrength = signalStrength
        self.temperatureCelsius = temperatureCelsius
        self.lastHeartbeat = lastHeartbeat
        self.sortIndex = sortIndex
    }

    /// Highest-priority problem first. Arming refuses the first one.
    var issues: [ZoneFault] {
        var found: [ZoneFault] = []
        if !isOnline { found.append(.offline) }
        if isTampered { found.append(.tamper) }
        if kind.hasContact && isContactOpen { found.append(.contactOpen) }
        if batteryPercent < ZoneRules.minimumBatteryPercent { found.append(.lowBattery) }
        return found
    }

    var primaryFault: ZoneFault? { issues.first }
}

nonisolated enum SystemMode: String, CaseIterable, Hashable, Sendable {
    case disarmed
    case home
    case away
}

/// What the current mix of zones actually is. `custom` means the switches
/// don't line up with Home or Away — usually after a single zone was changed.
nonisolated enum SystemPosture: String, Equatable, Sendable {
    case disarmed
    case home
    case away
    case custom
}
