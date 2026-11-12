//
//  AppCard.swift
//  SentinalX
//
//  Lab 01 AppCard, drawn with the SentinalX surface, stroke, and 24pt corners.
//

import SwiftUI

enum AppCardStyle {
    case standard
    case outlined
    case highlighted
}

struct AppCard<Content: View>: View {
    var title: String = ""
    var description: String = ""
    var systemImage: String? = nil
    var style: AppCardStyle = .standard
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var padding: CGFloat = 16
    private let content: Content

    @Environment(\.colorScheme) private var scheme

    init(
        title: String = "",
        description: String = "",
        systemImage: String? = nil,
        style: AppCardStyle = .standard,
        actionTitle: String? = nil,
        padding: CGFloat = 16,
        @ViewBuilder content: () -> Content,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.style = style
        self.actionTitle = actionTitle
        self.padding = padding
        self.action = action
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            if !title.isEmpty {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(SX.ink)
            }

            if !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(SX.secondary)
            }

            content

            if let actionTitle, let action {
                AppButton(title: actionTitle, style: .primary, action: action)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(padding)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .shadow(
            color: .black.opacity(scheme == .dark ? 0.28 : 0.06),
            radius: scheme == .dark ? 14 : 18,
            y: 8
        )
    }

    private var backgroundColor: Color {
        switch style {
        case .standard:
            SX.surface
        case .outlined:
            SX.surface.opacity(0.4)
        case .highlighted:
            SX.accent.opacity(0.12)
        }
    }

    private var borderColor: Color {
        switch style {
        case .standard:
            SX.stroke
        case .outlined, .highlighted:
            SX.accent.opacity(0.45)
        }
    }

    private var iconColor: Color {
        switch style {
        case .standard:
            SX.secondary
        case .outlined, .highlighted:
            SX.accent
        }
    }
}

extension AppCard where Content == EmptyView {
    init(
        title: String,
        description: String,
        systemImage: String? = nil,
        style: AppCardStyle = .standard,
        actionTitle: String? = nil,
        padding: CGFloat = 16,
        action: (() -> Void)? = nil
    ) {
        self.init(
            title: title,
            description: description,
            systemImage: systemImage,
            style: style,
            actionTitle: actionTitle,
            padding: padding,
            content: { EmptyView() },
            action: action
        )
    }
}
