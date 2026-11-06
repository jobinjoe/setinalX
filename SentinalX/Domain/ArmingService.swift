//
//  ArmingService.swift
//  SentinalX
//

import Foundation

nonisolated enum ArmingError: Error, Equatable, Sendable {
    case alreadyArmed
    case alreadyDisarmed
    case invalidPIN
    /// The zone cannot be armed until this clears. Disarming is still allowed.
    case blocked(ZoneFault)
}

nonisolated struct ZoneSkip: Equatable, Sendable {
    var zoneID: UUID
    var zoneName: String
    var fault: ZoneFault
}

nonisolated struct ArmingOutcome: Equatable, Sendable {
    var zones: [ZoneSnapshot]
    var skipped: [ZoneSkip]
}

/// Arm and disarm rules for one zone and for the whole site.
///
/// This type is deliberately pure: it takes values in and returns values
/// out. It does not read the PIN from storage, talk to SwiftData, or update
/// the screen. Callers persist the returned snapshots when the result is a
/// success. A failure leaves the caller's data untouched.
nonisolated struct ArmingService: Sendable {
    func arm(_ zone: ZoneSnapshot) -> Result<ZoneSnapshot, ArmingError> {
        if zone.isArmed {
            return .failure(.alreadyArmed)
        }
        if let fault = zone.primaryFault {
            return .failure(.blocked(fault))
        }
        var updated = zone
        updated.isArmed = true
        return .success(updated)
    }

    func disarm(
        _ zone: ZoneSnapshot,
        pin: String,
        expectedPIN: String
    ) -> Result<ZoneSnapshot, ArmingError> {
        if !zone.isArmed {
            return .failure(.alreadyDisarmed)
        }
        guard normalize(pin) == expectedPIN else {
            return .failure(.invalidPIN)
        }
        var updated = zone
        updated.isArmed = false
        return .success(updated)
    }

    /// Applies a site-wide mode.
    ///
    /// Home arms healthy entry and perimeter zones and turns interior zones off.
    /// Away arms every healthy zone. Faulted zones are forced off and reported
    /// in `skipped` — they are not a hard failure, because the rest of the
    /// site should still arm. Disarming the site asks for the PIN only when at
    /// least one zone is currently armed.
    func apply(
        _ mode: SystemMode,
        to zones: [ZoneSnapshot],
        pin: String,
        expectedPIN: String
    ) -> Result<ArmingOutcome, ArmingError> {
        if mode == .disarmed {
            let needsPIN = zones.contains(where: \.isArmed)
            if needsPIN && normalize(pin) != expectedPIN {
                return .failure(.invalidPIN)
            }
            let disarmed = zones.map { zone in
                var copy = zone
                copy.isArmed = false
                return copy
            }
            return .success(ArmingOutcome(zones: disarmed, skipped: []))
        }

        var skipped: [ZoneSkip] = []
        let updated = zones.map { zone -> ZoneSnapshot in
            var copy = zone
            guard wantsArmed(copy, mode: mode) else {
                copy.isArmed = false
                return copy
            }
            if let fault = copy.primaryFault {
                copy.isArmed = false
                skipped.append(ZoneSkip(zoneID: copy.id, zoneName: copy.name, fault: fault))
                return copy
            }
            copy.isArmed = true
            return copy
        }
        return .success(ArmingOutcome(zones: updated, skipped: skipped))
    }

    func posture(of zones: [ZoneSnapshot]) -> SystemPosture {
        guard zones.contains(where: \.isArmed) else { return .disarmed }

        let armable = zones.filter { $0.primaryFault == nil }
        let allArmableArmed = armable.allSatisfy(\.isArmed)
        let noFaultedArmed = zones.allSatisfy { $0.primaryFault == nil || !$0.isArmed }
        let interiors = zones.filter { $0.role == .interior }
        let perimeters = zones.filter { $0.role != .interior }
        let healthyInteriors = interiors.filter { $0.primaryFault == nil }
        let armablePerimeters = perimeters.filter { $0.primaryFault == nil }

        if allArmableArmed && noFaultedArmed {
            // Away means every zone that *can* arm is armed. A site with no
            // interior zones still counts. Faulted interiors are ignored.
            if !healthyInteriors.isEmpty || interiors.isEmpty {
                return .away
            }
        }

        let home = !armablePerimeters.isEmpty
            && armablePerimeters.allSatisfy(\.isArmed)
            && interiors.allSatisfy { !$0.isArmed }
            && noFaultedArmed
        if home { return .home }
        return .custom
    }

    private func wantsArmed(_ zone: ZoneSnapshot, mode: SystemMode) -> Bool {
        switch mode {
        case .disarmed:
            false
        case .home:
            zone.role != .interior
        case .away:
            true
        }
    }

    private func normalize(_ pin: String) -> String {
        pin.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
