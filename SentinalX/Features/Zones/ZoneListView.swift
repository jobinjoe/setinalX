//
//  ZoneListView.swift
//  SentinalX
//

import SwiftUI

struct ZoneListView: View {
    @Environment(AppModel.self) private var app
    @State private var filter: ZoneFilter = .all
    @State private var challenge: PINChallenge?

    var body: some View {
        ScreenBackdrop {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    postureCard
                    modePicker
                    if let banner = app.zones.banner {
                        NoticeBanner(text: banner) {
                            app.zones.banner = nil
                        }
                    }
                    ChipRow(options: Array(ZoneFilter.allCases), title: \.title, selection: $filter)
                    if visibleZones.isEmpty {
                        emptyFilter
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(visibleZones) { zone in
                                NavigationLink(value: zone.id) {
                                    ZoneCard(zone: zone)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    zoneMenu(zone)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
                .frame(maxWidth: 820)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Zones")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .refreshable {
            app.zones.reload()
        }
        .sheet(item: $challenge) { item in
            PINEntrySheet(
                title: item.title,
                message: item.message,
                failureCount: app.zones.pinFailures,
                errorText: app.zones.pinError
            ) { pin in
                let accepted: Bool
                switch item {
                case .disarmSystem:
                    accepted = app.zones.setMode(.disarmed, pin: pin)
                case .disarmZone(let id):
                    accepted = app.zones.disarm(id: id, pin: pin)
                }
                if accepted {
                    challenge = nil
                }
            }
        }
    }

    private var posture: SystemPosture { app.zones.posture }

    private var visibleZones: [ZoneSnapshot] {
        app.zones.zones.filter { zone in
            switch filter {
            case .all: true
            case .armed: zone.isArmed
            case .disarmed: !zone.isArmed
            case .attention: !zone.issues.isEmpty
            }
        }
    }

    private var armedCount: Int {
        app.zones.zones.filter(\.isArmed).count
    }

    private var attentionCount: Int {
        app.zones.zones.filter { !$0.issues.isEmpty }.count
    }

    private var postureCard: some View {
        AppCard(padding: 18) {
            postureContent
        }
    }

    private var postureContent: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(posture.tint.opacity(0.16))
                    .frame(width: 74, height: 74)
                Circle()
                    .stroke(posture.tint.opacity(0.45), lineWidth: 1)
                    .frame(width: 74, height: 74)
                Image(systemName: posture.symbol)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(posture.tint)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(greeting)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(SX.secondary)
                Text(posture.title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(SX.ink)
                Text(posture.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(SX.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 12) {
                    Label("\(armedCount) armed", systemImage: "lock.fill")
                    if attentionCount > 0 {
                        Label("\(attentionCount) need attention", systemImage: "exclamationmark.triangle.fill")
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(SX.secondary)
                .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private var modePicker: some View {
        HStack(spacing: 8) {
            ForEach(SystemMode.allCases, id: \.self) { mode in
                let selected = posture.matchingMode == mode
                Button {
                    select(mode)
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: mode.symbol)
                            .font(.body.weight(.semibold))
                        Text(mode.title)
                            .font(.caption.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(selected ? SX.labelOnFill(scheme) : SX.ink)
                    .background(selected ? fill(for: mode) : Color.clear, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(SX.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(SX.stroke, lineWidth: 1)
        )
        .animation(.spring(duration: 0.28), value: posture)
    }

    @Environment(\.colorScheme) private var scheme

    private func fill(for mode: SystemMode) -> Color {
        mode == .disarmed ? SX.safe : SX.armed
    }

    private var emptyFilter: some View {
        ContentUnavailableView {
            Label("Nothing in this filter", systemImage: "line.3.horizontal.decrease.circle")
        } description: {
            Text("Try another chip, or restore the demo layout in Settings.")
        }
    }

    @ViewBuilder
    private func zoneMenu(_ zone: ZoneSnapshot) -> some View {
        if zone.isArmed {
            Button("Disarm…", systemImage: "lock.open") {
                app.zones.pinError = nil
                challenge = .disarmZone(zone.id)
            }
        } else {
            Button("Arm", systemImage: "lock") {
                app.zones.arm(id: zone.id)
            }
        }
    }

    private func select(_ mode: SystemMode) {
        if posture.matchingMode == mode { return }
        if mode == .disarmed {
            app.zones.pinError = nil
            challenge = .disarmSystem
        } else {
            app.zones.setMode(mode, pin: "")
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let hello: String
        switch hour {
        case 5..<12: hello = "Good morning"
        case 12..<17: hello = "Good afternoon"
        case 17..<22: hello = "Good evening"
        default: hello = "Good night"
        }
        return "\(hello), \(app.session.operatorName)"
    }
}

struct ZoneCard: View {
    var zone: ZoneSnapshot

    var body: some View {
        AppCard(padding: 14) {
            zoneRow
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens zone details")
    }

    private var zoneRow: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill((zone.isArmed ? SX.armed : SX.safe).opacity(0.16))
                    .frame(width: 52, height: 52)
                Image(systemName: zone.kind.symbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(zone.isArmed ? SX.armed : SX.safe)
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(zone.name)
                        .font(.headline)
                        .foregroundStyle(SX.ink)
                    Spacer(minLength: 8)
                    StatusPill(armed: zone.isArmed)
                }
                Text("\(zone.role.label) · \(zone.kind.label)")
                    .font(.subheadline)
                    .foregroundStyle(SX.secondary)
                HStack(spacing: 12) {
                    Label("\(zone.batteryPercent)%", systemImage: batterySymbol(for: zone.batteryPercent))
                    if let fault = zone.primaryFault {
                        Label(ZoneCopy.faultTitle(fault), systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(SX.warning)
                    }
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(SX.secondary)
            }
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(SX.secondary)
        }
    }
}
