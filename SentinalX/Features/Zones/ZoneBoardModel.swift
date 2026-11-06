//
//  ZoneBoardModel.swift
//  SentinalX
//

import Foundation
import Observation

/// Screen state for the zone list and the zone screen.
/// Arming decisions go through `ArmingService`; this type only saves the
/// result and writes a panel event.
@MainActor
@Observable
final class ZoneBoardModel {
    private(set) var zones: [ZoneSnapshot] = []
    var banner: String?
    var pinError: String?
    var pinFailures = 0
    var feedbackTick = 0

    private let service = ArmingService()
    private let store: ZoneStore
    private let eventLog: EventLog
    private let session: SessionStore

    init(store: ZoneStore, eventLog: EventLog, session: SessionStore) {
        self.store = store
        self.eventLog = eventLog
        self.session = session
    }

    var posture: SystemPosture {
        service.posture(of: zones)
    }

    func zone(id: UUID) -> ZoneSnapshot? {
        zones.first { $0.id == id }
    }

    func prepare() {
        do {
            let seeded = try store.seedIfNeeded()
            zones = try store.load()
            try eventLog.reload()
            if seeded {
                try eventLog.append(DemoCatalog.welcomeEvent())
            }
        } catch {
            banner = "Couldn't read the zones saved on this device."
        }
    }

    func reload() {
        do {
            zones = try store.load()
        } catch {
            banner = "Couldn't refresh the saved zones."
        }
    }

    func arm(id: UUID) {
        guard let zone = zone(id: id) else { return }
        switch service.arm(zone) {
        case .failure(let error):
            note(error)
        case .success(let updated):
            commit(
                updated,
                title: "\(updated.name) armed",
                detail: "Armed from the zone screen.",
                severity: .notice
            )
        }
    }

    @discardableResult
    func disarm(id: UUID, pin: String) -> Bool {
        guard let zone = zone(id: id) else { return false }
        switch service.disarm(zone, pin: pin, expectedPIN: session.disarmPIN) {
        case .failure(let error):
            note(error)
            return false
        case .success(let updated):
            commit(
                updated,
                title: "\(updated.name) disarmed",
                detail: "Disarmed with the panel PIN.",
                severity: .notice
            )
            return true
        }
    }

    @discardableResult
    func setMode(_ mode: SystemMode, pin: String) -> Bool {
        switch service.apply(mode, to: zones, pin: pin, expectedPIN: session.disarmPIN) {
        case .failure(let error):
            note(error)
            return false
        case .success(let outcome):
            do {
                try store.save(outcome.zones)
            } catch {
                banner = "The new mode couldn't be saved on this device."
                return false
            }
            zones = outcome.zones
            pinError = nil
            feedbackTick += 1
            let headline = headline(for: mode)
            if outcome.skipped.isEmpty {
                banner = "\(headline)."
                record(
                    title: headline,
                    detail: "Every selected zone updated.",
                    severity: .notice,
                    zoneName: "All zones"
                )
            } else {
                let list = outcome.skipped.map { "\($0.zoneName) (\(ZoneCopy.faultTitle($0.fault).lowercased()))" }
                let detail = "Left disarmed: \(list.joined(separator: ", "))."
                banner = "\(headline). \(detail)"
                record(title: headline, detail: detail, severity: .warning, zoneName: "All zones")
                for skip in outcome.skipped {
                    record(
                        title: "Arming skipped",
                        detail: ZoneCopy.faultDetail(skip.fault),
                        severity: .warning,
                        zoneName: skip.zoneName
                    )
                }
            }
            return true
        }
    }

    func resetDemo() {
        do {
            try store.resetToDemo()
            zones = try store.load()
            try eventLog.clear()
            try eventLog.append(DemoCatalog.welcomeEvent())
            session.feedCursor = 0
            banner = "Demo layout restored."
            feedbackTick += 1
        } catch {
            banner = "Couldn't restore the demo layout."
        }
    }

    private func commit(
        _ updated: ZoneSnapshot,
        title: String,
        detail: String,
        severity: EventSeverity
    ) {
        guard let index = zones.firstIndex(where: { $0.id == updated.id }) else { return }
        var next = zones
        next[index] = updated
        do {
            try store.save(next)
        } catch {
            banner = "That change couldn't be saved on this device."
            return
        }
        zones = next
        banner = title
        pinError = nil
        feedbackTick += 1
        record(title: title, detail: detail, severity: severity, zoneName: updated.name)
    }

    private func record(title: String, detail: String, severity: EventSeverity, zoneName: String) {
        let event = SecurityEvent(
            id: UUID(),
            remoteID: nil,
            title: title,
            detail: detail,
            severity: severity,
            zoneName: zoneName,
            occurredAt: .now,
            source: .panel
        )
        do {
            try eventLog.append(event)
        } catch {
            banner = "The zone was saved, but the activity log could not be updated."
        }
    }

    private func note(_ error: ArmingError) {
        let message = ZoneCopy.message(for: error)
        banner = message
        if case .invalidPIN = error {
            pinError = message
            pinFailures += 1
        }
    }

    private func headline(for mode: SystemMode) -> String {
        switch mode {
        case .disarmed: "System disarmed"
        case .home: "Home mode set"
        case .away: "Away mode set"
        }
    }
}
