//
//  ArmingServiceTests.swift
//  SentinalXTests
//

import XCTest
@testable import SentinalX

final class ArmingServiceTests: XCTestCase {
    private let service = ArmingService()
    private let pin = DemoAccess.pin

    // MARK: - Single zone

    func testClearZoneCanBeArmed() {
        let zone = makeZone()
        let updated = requireSuccess(service.arm(zone))
        XCTAssertEqual(updated?.isArmed, true)
    }

    func testArmingPreservesSensorReadings() {
        let zone = makeZone(
            name: "Front Door",
            battery: 92,
            motion: 12,
            signal: 88,
            temperature: 21.4
        )
        let updated = requireSuccess(service.arm(zone))
        var expected = zone
        expected.isArmed = true
        XCTAssertEqual(updated, expected)
    }

    func testArmingAnArmedZoneFails() {
        let zone = makeZone(isArmed: true)
        XCTAssertEqual(service.arm(zone), .failure(.alreadyArmed))
        XCTAssertTrue(zone.isArmed)
    }

    func testOpenContactBlocksArming() {
        let zone = makeZone(kind: .door, role: .entry, isContactOpen: true)
        XCTAssertEqual(service.arm(zone), .failure(.blocked(.contactOpen)))
        XCTAssertFalse(zone.isArmed)
    }

    func testGlassBreakBlocksArming() {
        let zone = makeZone(kind: .glass, role: .perimeter, isContactOpen: true)
        XCTAssertEqual(service.arm(zone), .failure(.blocked(.contactOpen)))
    }

    func testLowBatteryBlocksArming() {
        let zone = makeZone(battery: ZoneRules.minimumBatteryPercent - 1)
        XCTAssertEqual(service.arm(zone), .failure(.blocked(.lowBattery)))
        XCTAssertFalse(zone.isArmed)
    }

    func testBatteryAtThresholdCanArm() {
        let zone = makeZone(battery: ZoneRules.minimumBatteryPercent)
        XCTAssertEqual(requireSuccess(service.arm(zone))?.isArmed, true)
        XCTAssertEqual(ZoneRules.minimumBatteryPercent, 20)
    }

    func testTamperBlocksArming() {
        let zone = makeZone(isTampered: true)
        XCTAssertEqual(service.arm(zone), .failure(.blocked(.tamper)))
    }

    func testOfflineBlocksArming() {
        let zone = makeZone(isOnline: false)
        XCTAssertEqual(service.arm(zone), .failure(.blocked(.offline)))
    }

    func testOfflineOutranksLowBattery() {
        let zone = makeZone(battery: 5, isOnline: false)
        XCTAssertEqual(zone.primaryFault, .offline)
        XCTAssertEqual(service.arm(zone), .failure(.blocked(.offline)))
    }

    func testMotionZoneIgnoresStaleContactFlag() {
        let zone = makeZone(kind: .motion, role: .interior, isContactOpen: true)
        XCTAssertNil(zone.primaryFault)
        XCTAssertEqual(requireSuccess(service.arm(zone))?.isArmed, true)
    }

    func testDisarmWithCorrectPIN() {
        let zone = makeZone(isArmed: true)
        let updated = requireSuccess(service.disarm(zone, pin: pin, expectedPIN: pin))
        XCTAssertEqual(updated?.isArmed, false)
    }

    func testDisarmTrimsWhitespaceAroundPIN() {
        let zone = makeZone(isArmed: true)
        let updated = requireSuccess(service.disarm(zone, pin: "  \(pin)\n", expectedPIN: pin))
        XCTAssertEqual(updated?.isArmed, false)
    }

    func testDisarmWithWrongPINLeavesZoneArmed() {
        let zone = makeZone(isArmed: true)
        XCTAssertEqual(service.disarm(zone, pin: "0000", expectedPIN: pin), .failure(.invalidPIN))
        XCTAssertEqual(service.disarm(zone, pin: "", expectedPIN: pin), .failure(.invalidPIN))
        XCTAssertTrue(zone.isArmed)
    }

    func testDisarmWhenAlreadyDisarmed() {
        let zone = makeZone(isArmed: false)
        XCTAssertEqual(service.disarm(zone, pin: pin, expectedPIN: pin), .failure(.alreadyDisarmed))
    }

    func testDisarmAllowedWhileContactIsOpen() {
        let zone = makeZone(isArmed: true, isContactOpen: true)
        let updated = requireSuccess(service.disarm(zone, pin: pin, expectedPIN: pin))
        XCTAssertEqual(updated?.isArmed, false)
        XCTAssertEqual(updated?.isContactOpen, true)
    }

    // MARK: - Site modes

    func testHomeModeArmsPerimeterAndDisarmsInterior() {
        let entry = makeZone(name: "Front Door", role: .entry, isArmed: false)
        let window = makeZone(name: "Kitchen Window", kind: .window, role: .perimeter, isArmed: true, battery: 10)
        let living = makeZone(name: "Living Room", kind: .motion, role: .interior, isArmed: true)
        let hallway = makeZone(name: "Hallway", kind: .motion, role: .interior, isOnline: false)

        let outcome = requireOutcome(service.apply(.home, to: [entry, window, living, hallway], pin: "wrong", expectedPIN: pin))

        guard let outcome else { return }
        XCTAssertEqual(outcome.zones.map(\.isArmed), [true, false, false, false])
        XCTAssertEqual(outcome.skipped.map(\.zoneName), ["Kitchen Window"])
        XCTAssertEqual(outcome.skipped.first?.fault, .lowBattery)
        XCTAssertEqual(service.posture(of: outcome.zones), .home)
    }

    func testAwayModeSkipsFaultsAndTurnsThemOff() {
        let entry = makeZone(name: "Front Door", role: .entry, isArmed: false)
        let living = makeZone(name: "Living Room", kind: .motion, role: .interior, isArmed: false)
        let gate = makeZone(name: "Back Gate", kind: .gate, role: .perimeter, isArmed: true, isContactOpen: true)
        let window = makeZone(name: "Kitchen Window", kind: .window, role: .perimeter, battery: 19)

        let outcome = requireOutcome(service.apply(.away, to: [entry, living, gate, window], pin: "", expectedPIN: pin))

        guard let outcome else { return }
        XCTAssertEqual(outcome.zones.map(\.name), ["Front Door", "Living Room", "Back Gate", "Kitchen Window"])
        XCTAssertEqual(outcome.zones.map(\.isArmed), [true, true, false, false])
        XCTAssertEqual(outcome.skipped.map(\.fault), [.contactOpen, .lowBattery])
        XCTAssertEqual(service.posture(of: outcome.zones), .away)
    }

    func testDisarmSystemRequiresPINWhenAnythingIsArmed() {
        let zones = [makeZone(name: "Front Door", isArmed: true), makeZone(name: "Hallway", isArmed: false)]
        XCTAssertEqual(
            service.apply(.disarmed, to: zones, pin: "9999", expectedPIN: pin),
            .failure(.invalidPIN)
        )
    }

    func testWrongPINDoesNotProduceANewLayout() {
        let zones = [makeZone(isArmed: true), makeZone(name: "Hallway", role: .interior, isArmed: true)]
        let result = service.apply(.disarmed, to: zones, pin: "0000", expectedPIN: pin)
        guard case .failure(.invalidPIN) = result else {
            return XCTFail("Expected the PIN to be rejected")
        }
        XCTAssertEqual(zones.map(\.isArmed), [true, true])
    }

    func testDisarmSystemWithCorrectPIN() {
        let zones = [
            makeZone(name: "Front Door", isArmed: true),
            makeZone(name: "Hallway", kind: .motion, role: .interior, isArmed: true)
        ]
        let outcome = requireOutcome(service.apply(.disarmed, to: zones, pin: " \(pin) ", expectedPIN: pin))
        guard let outcome else { return }
        XCTAssertEqual(outcome.zones.map(\.isArmed), [false, false])
        XCTAssertEqual(outcome.skipped, [])
        XCTAssertEqual(service.posture(of: outcome.zones), .disarmed)
    }

    func testDisarmSystemDoesNotNeedAPINWhenNothingIsArmed() {
        let zones = [makeZone(isArmed: false), makeZone(name: "Hallway", isArmed: false, isContactOpen: true)]
        let outcome = requireOutcome(service.apply(.disarmed, to: zones, pin: "", expectedPIN: pin))
        guard let outcome else { return }
        XCTAssertEqual(outcome.zones.map(\.isArmed), [false, false])
    }

    // MARK: - Posture

    func testPostureDetectsTheFourStates() {
        let entry = makeZone(name: "Front Door", role: .entry, isArmed: true)
        let interior = makeZone(name: "Living Room", kind: .motion, role: .interior, isArmed: false)
        XCTAssertEqual(service.posture(of: [entry, interior]), .home)

        var awayInterior = interior
        awayInterior.isArmed = true
        XCTAssertEqual(service.posture(of: [entry, awayInterior]), .away)

        var disarmedEntry = entry
        disarmedEntry.isArmed = false
        XCTAssertEqual(service.posture(of: [disarmedEntry, interior]), .disarmed)

        XCTAssertEqual(service.posture(of: [disarmedEntry, awayInterior]), .custom)
    }

    func testDemoCatalogStartsInHomePosture() {
        let zones = DemoCatalog.zones(now: Date(timeIntervalSince1970: 0))
        XCTAssertEqual(service.posture(of: zones), .home)
        XCTAssertEqual(zones.filter(\.isArmed).map(\.name), ["Front Door", "Garage Entry"])
        XCTAssertEqual(zones.first { $0.name == "Kitchen Window" }?.primaryFault, .lowBattery)
        XCTAssertEqual(zones.first { $0.name == "Back Gate" }?.primaryFault, .contactOpen)
    }

    // MARK: - Helpers

    private func requireSuccess(
        _ result: Result<ZoneSnapshot, ArmingError>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> ZoneSnapshot? {
        guard case .success(let zone) = result else {
            XCTFail("Expected success, got \(result)", file: file, line: line)
            return nil
        }
        return zone
    }

    private func requireOutcome(
        _ result: Result<ArmingOutcome, ArmingError>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> ArmingOutcome? {
        guard case .success(let outcome) = result else {
            XCTFail("Expected success, got \(result)", file: file, line: line)
            return nil
        }
        return outcome
    }

    private func makeZone(
        name: String = "Front Door",
        kind: ZoneKind = .door,
        role: ZoneRole = .entry,
        isArmed: Bool = false,
        battery: Int = 80,
        isContactOpen: Bool = false,
        motion: Int = 0,
        isTampered: Bool = false,
        isOnline: Bool = true,
        signal: Int = 80,
        temperature: Double = 21
    ) -> ZoneSnapshot {
        ZoneSnapshot(
            id: UUID(),
            name: name,
            kind: kind,
            role: role,
            isArmed: isArmed,
            batteryPercent: battery,
            isContactOpen: isContactOpen,
            motionLevel: motion,
            isTampered: isTampered,
            isOnline: isOnline,
            signalStrength: signal,
            temperatureCelsius: temperature,
            lastHeartbeat: Date(timeIntervalSince1970: 1_700_000_000),
            sortIndex: 0
        )
    }
}
