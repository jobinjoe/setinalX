//
//  EventFeedView.swift
//  SentinalX
//

import SwiftUI

struct EventFeedView: View {
    @Environment(AppModel.self) private var app
    @State private var filter: EventFilter = .all
    @State private var expanded: Set<UUID> = []

    var body: some View {
        ScreenBackdrop {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    ChipRow(options: Array(EventFilter.allCases), title: \.title, selection: $filter)
                    if visible.isEmpty {
                        empty
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(visible.enumerated()), id: \.element.id) { index, event in
                                EventRow(
                                    event: event,
                                    showsRail: index < visible.count - 1,
                                    expanded: expanded.contains(event.id)
                                ) {
                                    if expanded.contains(event.id) {
                                        expanded.remove(event.id)
                                    } else {
                                        expanded.insert(event.id)
                                    }
                                }
                            }
                        }
                    }
                    Text("Cloud rows are posts from jsonplaceholder.typicode.com. Each one is tagged with a zone and a severity; the title and body are the payload.")
                        .font(.footnote)
                        .foregroundStyle(SX.secondary)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
                .frame(maxWidth: 820)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Activity")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            Button {
                Task { await app.feed.refreshNow() }
            } label: {
                if app.feed.isPulling {
                    ProgressView()
                } else {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .accessibilityLabel("Check for events now")
        }
        .refreshable {
            await app.feed.refreshNow()
        }
        .task(id: app.session.liveFeedToken) {
            await app.feed.run()
        }
    }

    private var visible: [SecurityEvent] {
        app.log.events.filter { event in
            switch filter {
            case .all: true
            case .panel: event.source == .panel
            case .cloud: event.source == .cloud
            case .alerts: event.severity == .warning || event.severity == .critical
            }
        }
    }

    private var header: some View {
        AppCard {
            HStack(spacing: 12) {
                LiveDot(active: app.feed.link == .live, color: dotColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(linkTitle)
                        .font(.headline)
                        .foregroundStyle(SX.ink)
                    Text(linkSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(SX.secondary)
                }
                Spacer()
            }
        }
    }

    private var dotColor: Color {
        switch app.feed.link {
        case .live: SX.safe
        case .checking: SX.accent
        case .paused: SX.secondary
        case .offline: SX.warning
        }
    }

    private var linkTitle: String {
        switch app.feed.link {
        case .live: "Live"
        case .checking: "Checking"
        case .paused: "Feed paused"
        case .offline: "Offline"
        }
    }

    private var linkSubtitle: String {
        switch app.feed.link {
        case .live:
            "New posts arrive about every \(app.session.pollSeconds)s."
        case .checking:
            "Asking JSONPlaceholder for the next page."
        case .paused:
            "Automatic checks are off. You can still check now."
        case .offline:
            "The event service didn't respond. Saved events are still here."
        }
    }

    private var empty: some View {
        ContentUnavailableView {
            Label("No events in this view", systemImage: "waveform.path.ecg")
        } description: {
            Text("Panel actions and cloud posts will collect here.")
        } actions: {
            Button("Check now") {
                Task { await app.feed.refreshNow() }
            }
        }
    }
}

private struct LiveDot: View {
    var active: Bool
    var color: Color
    @State private var pulse = false

    var body: some View {
        ZStack {
            if active {
                Circle()
                    .stroke(color.opacity(0.45), lineWidth: 2)
                    .frame(width: 10, height: 10)
                    .scaleEffect(pulse ? 2.4 : 1)
                    .opacity(pulse ? 0 : 1)
            }
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
        }
        .frame(width: 22, height: 22)
        .onAppear { restartPulse() }
        .onChange(of: active) { _, _ in
            restartPulse()
        }
        .accessibilityHidden(true)
    }

    private func restartPulse() {
        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) { pulse = false }
        guard active else { return }
        withAnimation(.easeOut(duration: 1.3).repeatForever(autoreverses: false)) {
            pulse = true
        }
    }
}

private struct EventRow: View {
    var event: SecurityEvent
    var showsRail: Bool
    var expanded: Bool
    var onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Image(systemName: event.severity.symbol)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(event.severity.tint)
                    .frame(width: 28, height: 28)
                    .background(event.severity.tint.opacity(0.14), in: Circle())
                if showsRail {
                    Rectangle()
                        .fill(SX.stroke)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 28)

            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(event.severity.label)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(event.severity.tint)
                        Label(event.source.label, systemImage: event.source.symbol)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(SX.secondary)
                        Spacer()
                        Text(event.occurredAt, style: .relative)
                            .font(.caption)
                            .foregroundStyle(SX.secondary)
                    }
                    Text(event.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SX.ink)
                        .multilineTextAlignment(.leading)
                    Text(event.detail)
                        .font(.footnote)
                        .foregroundStyle(SX.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(expanded ? nil : 3)
                    Text(event.zoneName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SX.accent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 18)
            }
            .buttonStyle(.plain)
        }
    }
}
