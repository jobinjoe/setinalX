//
//  AppButton.swift
//  SentinalX
//
//  Lab 01 AppButton, drawn with the SentinalX palette.
//

import SwiftUI

enum AppButtonStyle {
    case primary
    case secondary
    case outlined
    case destructive
}

struct AppButton: View {
    let title: String
    var style: AppButtonStyle = .primary
    var systemImage: String? = nil
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var tint: Color? = nil
    let action: () -> Void

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: {
            if isEnabled { action() }
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(labelColor)
                } else if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(labelColor)
            .background {
                Capsule().fill(fillColor)
            }
            .overlay {
                Capsule().strokeBorder(SX.stroke, lineWidth: showsStroke ? 1 : 0)
            }
        }
        .buttonStyle(PressableButtonStyle(enabled: isEnabled))
        .allowsHitTesting(isEnabled)
        .accessibilityAddTraits(isDisabled ? .isStaticText : [])
    }

    private var isEnabled: Bool {
        !isDisabled && !isLoading
    }

    private var fillColor: Color {
        if isDisabled { return SX.surfaceRaised }
        if let tint { return tint }
        switch style {
        case .primary:
            return SX.accent
        case .secondary, .outlined:
            return SX.surface
        case .destructive:
            return SX.critical
        }
    }

    private var labelColor: Color {
        if isDisabled { return SX.ink }
        if tint != nil { return SX.labelOnFill(scheme) }
        switch style {
        case .primary, .destructive:
            return SX.labelOnFill(scheme)
        case .secondary, .outlined:
            return SX.ink
        }
    }

    private var showsStroke: Bool {
        isDisabled || style == .outlined || style == .secondary
    }
}

private struct PressableButtonStyle: ButtonStyle {
    var enabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed && enabled ? 0.88 : 1)
    }
}
