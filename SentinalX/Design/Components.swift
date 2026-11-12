//
//  Components.swift
//  SentinalX
//

import SwiftUI

struct StatusPill: View {
    var armed: Bool
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: armed ? "lock.fill" : "lock.open.fill")
                .font(.caption2.weight(.bold))
            Text(armed ? "Armed" : "Disarmed")
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .foregroundStyle(SX.labelOnFill(scheme))
        .background(armed ? SX.armed : SX.safe, in: Capsule())
        .accessibilityLabel(armed ? "Armed" : "Disarmed")
    }
}

struct ChipRow<Option: Identifiable & Hashable>: View {
    var options: [Option]
    var title: (Option) -> String
    @Binding var selection: Option

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options) { option in
                    let isSelected = option == selection
                    Button {
                        selection = option
                    } label: {
                        Text(title(option))
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .foregroundStyle(isSelected ? SX.background : SX.ink)
                            .background(isSelected ? SX.ink : SX.surface, in: Capsule())
                            .overlay(Capsule().stroke(SX.stroke, lineWidth: isSelected ? 0 : 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }
}

struct MeterBar: View {
    var progress: Double
    var tint: Color

    var body: some View {
        GeometryReader { geo in
            let width = max(8, geo.size.width * min(max(progress, 0), 1))
            ZStack(alignment: .leading) {
                Capsule().fill(SX.stroke)
                Capsule().fill(tint).frame(width: width)
            }
        }
        .frame(height: 8)
        .accessibilityValue("\(Int((min(max(progress, 0), 1)) * 100)) percent")
    }
}

struct RingGauge: View {
    var progress: Double
    var tint: Color
    var label: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(SX.stroke, lineWidth: 8)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(tint, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(Int(min(max(progress, 0), 1) * 100))")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(SX.ink)
                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(SX.secondary)
            }
        }
        .frame(width: 78, height: 78)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) \(Int(min(max(progress, 0), 1) * 100)) percent")
    }
}

struct NoticeBanner: View {
    var text: String
    var onDismiss: () -> Void

    var body: some View {
        AppCard(padding: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(SX.accent)
                    .padding(.top, 2)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(SX.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SX.secondary)
                        .padding(6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss")
            }
        }
    }
}

struct MetricTile: View {
    var title: String
    var value: String
    var caption: String
    var symbol: String
    var tint: Color
    var progress: Double?

    var body: some View {
        AppCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Label(title, systemImage: symbol)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(SX.secondary)
                Text(value)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let progress {
                    MeterBar(progress: progress, tint: tint)
                }
                Text(caption)
                    .font(.footnote)
                    .foregroundStyle(SX.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct SuccessHaptic: ViewModifier {
    var tick: Int
    var enabled: Bool

    func body(content: Content) -> some View {
        #if os(iOS) || os(macOS)
        if enabled {
            content.sensoryFeedback(.success, trigger: tick)
        } else {
            content
        }
        #else
        content
        #endif
    }
}

enum PINChallenge: Identifiable {
    case disarmSystem
    case disarmZone(UUID)

    var id: String {
        switch self {
        case .disarmSystem: "system"
        case .disarmZone(let id): id.uuidString
        }
    }

    var title: String {
        switch self {
        case .disarmSystem: "Disarm the system"
        case .disarmZone: "Disarm this zone"
        }
    }

    var message: String {
        "Enter the 4-digit panel PIN. The demo PIN is \(DemoAccess.pin) until you change it."
    }
}

struct PINEntrySheet: View {
    var title: String
    var message: String
    var failureCount: Int
    var errorText: String?
    var onSubmit: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pin = ""
    @State private var shakes: CGFloat = 0

    private let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "del"]

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(SX.ink)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(SX.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)

            HStack(spacing: 14) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index < pin.count ? SX.accent : SX.stroke)
                        .frame(width: 14, height: 14)
                }
            }
            .modifier(ShakeEffect(shakes: shakes))

            if let errorText {
                Text(errorText)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(SX.critical)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(keys, id: \.self) { key in
                    keyButton(key)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(SX.background)
        #if os(iOS)
        .presentationDetents([.height(560)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        #endif
        .onChange(of: failureCount) { _, _ in
            pin = ""
            withAnimation(.linear(duration: 0.35)) {
                shakes += 1
            }
        }
    }

    @ViewBuilder
    private func keyButton(_ key: String) -> some View {
        if key.isEmpty {
            Color.clear.frame(height: 64)
        } else {
            Button {
                tap(key)
            } label: {
                Group {
                    if key == "del" {
                        Image(systemName: "delete.left")
                            .font(.title3.weight(.medium))
                    } else {
                        Text(key)
                            .font(.system(.title2, design: .rounded, weight: .medium))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .foregroundStyle(SX.ink)
                .background(SX.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(SX.stroke, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(key == "del" ? "Delete" : key)
        }
    }

    private func tap(_ key: String) {
        if key == "del" {
            if !pin.isEmpty { pin.removeLast() }
            return
        }
        guard pin.count < 4 else { return }
        pin.append(key)
        if pin.count == 4 {
            onSubmit(pin)
        }
    }
}

private struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat
    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = 8 * sin(shakes * .pi * 2)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

struct SettingsGroup<Content: View>: View {
    var title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(SX.secondary)
                .padding(.leading, 4)
            VStack(spacing: 0) {
                content()
            }
            .background(SX.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(SX.stroke, lineWidth: 1)
            )
        }
    }
}

struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(SX.stroke)
            .frame(height: 1)
            .padding(.leading, 16)
    }
}
