//
//  ZoneDetailView.swift
//  SentinalX
//

import SwiftUI

struct ZoneDetailView: View {
    var zoneID: UUID

    @Environment(AppModel.self) private var app
    @State private var challenge: PINChallenge?

    var body: some View {
        ScreenBackdrop {
            if let zone = app.zones.zone(id: zoneID) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        hero(zone)
                        if !zone.issues.isEmpty {
                            issueCard(zone)
                        }
                        action(zone)
                        if let banner = app.zones.banner {
                            NoticeBanner(text: banner) {
                                app.zones.banner = nil
                            }
                        }
                        readings(zone)
                        recent(zone)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                    .frame(maxWidth: 820)
                    .frame(maxWidth: .infinity)
                }
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .navigationTitle(zone.name)
            } else {
                ContentUnavailableView {
                    Label("Zone unavailable", systemImage: "shield.slash")
                } description: {
                    Text("This zone is no longer in the local store.")
                }
            }
        }
        .sheet(item: $challenge) { item in
            PINEntrySheet(
                title: item.title,
                message: item.message,
                failureCount: app.zones.pinFailures,
                errorText: app.zones.pinError
            ) { pin in
                if app.zones.disarm(id: zoneID, pin: pin) {
                    challenge = nil
                }
            }
        }
    }

    private func hero(_ zone: ZoneSnapshot) -> some View {
        AppCard(padding: 18) {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill((zone.isArmed ? SX.armed : SX.safe).opacity(0.16))
                        .frame(width: 72, height: 72)
                    Image(systemName: zone.kind.symbol)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(zone.isArmed ? SX.armed : SX.safe)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(zone.name)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(SX.ink)
                    Text("\(zone.role.label) · \(zone.kind.label)")
                        .font(.subheadline)
                        .foregroundStyle(SX.secondary)
                    StatusPill(armed: zone.isArmed)
                }
                Spacer(minLength: 8)
                RingGauge(
                    progress: Double(zone.batteryPercent) / 100,
                    tint: zone.batteryPercent < ZoneRules.minimumBatteryPercent ? SX.warning : SX.safe,
                    label: "Batt"
                )
            }
        }
    }

    private func issueCard(_ zone: ZoneSnapshot) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("Needs attention before arming", systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SX.warning)
                ForEach(zone.issues, id: \.self) { fault in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ZoneCopy.faultTitle(fault))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SX.ink)
                        Text(ZoneCopy.faultDetail(fault))
                            .font(.footnote)
                            .foregroundStyle(SX.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func action(_ zone: ZoneSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if zone.isArmed {
                AppButton(
                    title: "Disarm zone",
                    style: .primary,
                    systemImage: "lock.open.fill",
                    tint: SX.accent
                ) {
                    app.zones.pinError = nil
                    challenge = .disarmZone(zone.id)
                }
                Text("Disarming asks for the panel PIN.")
                    .font(.footnote)
                    .foregroundStyle(SX.secondary)
            } else {
                AppButton(
                    title: zone.primaryFault == nil ? "Arm zone" : "Cannot arm",
                    style: .primary,
                    systemImage: "lock.fill",
                    isDisabled: zone.primaryFault != nil,
                    tint: SX.armed
                ) {
                    app.zones.arm(id: zone.id)
                }
                if let fault = zone.primaryFault {
                    Text(ZoneCopy.faultDetail(fault))
                        .font(.footnote)
                        .foregroundStyle(SX.warning)
                }
            }
        }
    }

    private func readings(_ zone: ZoneSnapshot) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            sensorTile(zone)
            MetricTile(
                title: "Battery",
                value: "\(zone.batteryPercent)%",
                caption: zone.batteryPercent < ZoneRules.minimumBatteryPercent
                    ? "Below the \(ZoneRules.minimumBatteryPercent)% arming floor."
                    : "Above the arming floor.",
                symbol: batterySymbol(for: zone.batteryPercent),
                tint: zone.batteryPercent < ZoneRules.minimumBatteryPercent ? SX.warning : SX.safe,
                progress: Double(zone.batteryPercent) / 100
            )
            MetricTile(
                title: "Signal",
                value: signalLabel(for: zone.signalStrength),
                caption: "\(zone.signalStrength)% link to the panel.",
                symbol: "antenna.radiowaves.left.and.right",
                tint: SX.accent,
                progress: Double(zone.signalStrength) / 100
            )
            MetricTile(
                title: "Ambient",
                value: String(format: "%.1f°", zone.temperatureCelsius),
                caption: "Temperature reported by the sensor.",
                symbol: "thermometer.medium",
                tint: SX.accent,
                progress: nil
            )
            MetricTile(
                title: "Heartbeat",
                value: zone.isOnline ? "Online" : "Offline",
                caption: "Last check-in \(zone.lastHeartbeat.formatted(.relative(presentation: .named))).",
                symbol: zone.isOnline ? "wave.3.right" : "wifi.slash",
                tint: zone.isOnline ? SX.safe : SX.critical,
                progress: nil
            )
            MetricTile(
                title: "Integrity",
                value: zone.isTampered ? "Tamper" : "Sealed",
                caption: zone.isTampered ? "The case may have been opened." : "No tamper reported.",
                symbol: zone.isTampered ? "exclamationmark.shield.fill" : "checkmark.shield.fill",
                tint: zone.isTampered ? SX.critical : SX.safe,
                progress: nil
            )
        }
    }

    private func sensorTile(_ zone: ZoneSnapshot) -> some View {
        let value: String
        let caption: String
        let progress: Double?
        let tint: Color
        if zone.kind.hasContact {
            let open = zone.isContactOpen
            value = open ? "Open" : "Closed"
            caption = open ? "The contact is broken." : "The contact is seated."
            progress = open ? 1 : 0.08
            tint = open ? SX.critical : SX.safe
        } else {
            value = "\(zone.motionLevel)%"
            caption = "Current activity on this sensor."
            progress = Double(zone.motionLevel) / 100
            tint = zone.motionLevel > 40 ? SX.warning : SX.accent
        }
        return MetricTile(
            title: zone.kind.label,
            value: value,
            caption: caption,
            symbol: zone.kind.symbol,
            tint: tint,
            progress: progress
        )
    }

    @ViewBuilder
    private func recent(_ zone: ZoneSnapshot) -> some View {
        let rows = app.log.events.filter { $0.zoneName == zone.name }.prefix(4)
        VStack(alignment: .leading, spacing: 10) {
            Text("RECENT ON THIS ZONE")
                .font(.caption.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(SX.secondary)
            if rows.isEmpty {
                AppCard {
                    Text("No saved events for this zone yet.")
                        .font(.subheadline)
                        .foregroundStyle(SX.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                AppCard {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(rows)) { event in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(event.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(SX.ink)
                                    Spacer()
                                    Text(event.occurredAt, style: .relative)
                                        .font(.caption)
                                        .foregroundStyle(SX.secondary)
                                }
                                Text(event.detail)
                                    .font(.footnote)
                                    .foregroundStyle(SX.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}
