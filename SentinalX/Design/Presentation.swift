//
//  Presentation.swift
//  SentinalX
//

import SwiftUI

enum ZoneCopy {
    static func message(for error: ArmingError) -> String {
        switch error {
        case .alreadyArmed:
            "This zone is already armed."
        case .alreadyDisarmed:
            "This zone is already disarmed."
        case .invalidPIN:
            "That PIN doesn't match."
        case .blocked(let fault):
            faultDetail(fault)
        }
    }

    static func faultTitle(_ fault: ZoneFault) -> String {
        switch fault {
        case .offline: "Offline"
        case .tamper: "Tamper"
        case .contactOpen: "Open"
        case .lowBattery: "Low battery"
        }
    }

    static func faultDetail(_ fault: ZoneFault) -> String {
        switch fault {
        case .offline:
            "This sensor is offline, so it can't be armed."
        case .tamper:
            "The sensor case looks open. Clear the tamper before arming."
        case .contactOpen:
            "Close this sensor before arming."
        case .lowBattery:
            "Battery is under \(ZoneRules.minimumBatteryPercent)%. Replace it before arming."
        }
    }
}

extension ZoneKind {
    var symbol: String {
        switch self {
        case .door: "door.left.hand.closed"
        case .window: "window.vertical.closed"
        case .gate: "door.garage.closed"
        case .motion: "sensor.fill"
        case .glass: "waveform.path"
        }
    }

    var label: String {
        switch self {
        case .door, .window, .gate: "Contact"
        case .motion: "Motion"
        case .glass: "Glass break"
        }
    }
}

extension ZoneRole {
    var label: String {
        switch self {
        case .entry: "Entry"
        case .perimeter: "Perimeter"
        case .interior: "Interior"
        }
    }
}

extension SystemMode {
    var title: String {
        switch self {
        case .disarmed: "Disarm"
        case .home: "Home"
        case .away: "Away"
        }
    }

    var symbol: String {
        switch self {
        case .disarmed: "lock.open.fill"
        case .home: "house.fill"
        case .away: "figure.walk.departure"
        }
    }
}

extension SystemPosture {
    var title: String {
        switch self {
        case .disarmed: "Disarmed"
        case .home: "Home"
        case .away: "Away"
        case .custom: "Custom"
        }
    }

    var subtitle: String {
        switch self {
        case .disarmed:
            "Every zone is standing by."
        case .home:
            "The shell is armed. Interior sensors are off."
        case .away:
            "Every clear zone is armed."
        case .custom:
            "This mix doesn't match Home or Away."
        }
    }

    var symbol: String {
        switch self {
        case .disarmed: "lock.open.fill"
        case .home: "house.fill"
        case .away: "figure.walk.departure"
        case .custom: "square.grid.2x2.fill"
        }
    }

    var tint: Color {
        switch self {
        case .disarmed: SX.safe
        case .home, .away: SX.armed
        case .custom: SX.warning
        }
    }

    var matchingMode: SystemMode? {
        switch self {
        case .disarmed: .disarmed
        case .home: .home
        case .away: .away
        case .custom: nil
        }
    }
}

extension EventSeverity {
    var label: String {
        switch self {
        case .info: "Info"
        case .notice: "Notice"
        case .warning: "Warning"
        case .critical: "Critical"
        }
    }

    var symbol: String {
        switch self {
        case .info: "info.circle.fill"
        case .notice: "bell.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .critical: "exclamationmark.octagon.fill"
        }
    }

    var tint: Color {
        switch self {
        case .info: SX.secondary
        case .notice: SX.accent
        case .warning: SX.warning
        case .critical: SX.critical
        }
    }
}

extension EventSource {
    var label: String {
        switch self {
        case .panel: "Panel"
        case .cloud: "Cloud"
        }
    }

    var symbol: String {
        switch self {
        case .panel: "rectangle.connected.to.line.below"
        case .cloud: "cloud.fill"
        }
    }
}

enum ZoneFilter: String, CaseIterable, Identifiable, Hashable {
    case all
    case armed
    case disarmed
    case attention

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .armed: "Armed"
        case .disarmed: "Disarmed"
        case .attention: "Attention"
        }
    }
}

enum EventFilter: String, CaseIterable, Identifiable, Hashable {
    case all
    case panel
    case cloud
    case alerts

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .panel: "Panel"
        case .cloud: "Cloud"
        case .alerts: "Alerts"
        }
    }
}

func batterySymbol(for percent: Int) -> String {
    switch percent {
    case ..<10: "battery.0percent"
    case ..<40: "battery.25percent"
    case ..<70: "battery.50percent"
    case ..<90: "battery.75percent"
    default: "battery.100percent"
    }
}

func signalLabel(for strength: Int) -> String {
    switch strength {
    case ..<40: "Weak"
    case ..<70: "Fair"
    default: "Strong"
    }
}
