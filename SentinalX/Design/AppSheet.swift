//
//  AppSheet.swift
//  SentinalX
//
//  Lab 01 AppSheet, drawn with the SentinalX palette and AppButton.
//

import SwiftUI

enum AppSheetStyle {
    case info
    case confirmation
    case destructive
}

struct AppSheet<Content: View>: View {
    let title: String
    let message: String
    var style: AppSheetStyle = .confirmation
    var confirmTitle: String = "OK"
    var cancelTitle: String? = nil
    let onConfirm: () -> Void
    var onCancel: (() -> Void)? = nil
    private let content: Content

    @Environment(\.dismiss) private var dismiss

    init(
        title: String,
        message: String,
        style: AppSheetStyle = .confirmation,
        confirmTitle: String = "OK",
        cancelTitle: String? = nil,
        @ViewBuilder content: () -> Content,
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.style = style
        self.confirmTitle = confirmTitle
        self.cancelTitle = cancelTitle
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        self.content = content()
    }

    private var iconName: String {
        switch style {
        case .info:
            "info.circle.fill"
        case .confirmation:
            "checkmark.circle.fill"
        case .destructive:
            "trash.fill"
        }
    }

    private var iconColor: Color {
        style == .destructive ? SX.critical : SX.accent
    }

    private var confirmButtonStyle: AppButtonStyle {
        style == .destructive ? .destructive : .primary
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 40))
                .foregroundStyle(iconColor)

            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(SX.ink)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.body)
                .foregroundStyle(SX.secondary)
                .multilineTextAlignment(.center)

            content

            VStack(spacing: 12) {
                AppButton(title: confirmTitle, style: confirmButtonStyle) {
                    onConfirm()
                    dismiss()
                }

                if let cancelTitle {
                    AppButton(title: cancelTitle, style: .secondary) {
                        onCancel?()
                        dismiss()
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(SX.background)
    }
}

extension AppSheet where Content == EmptyView {
    init(
        title: String,
        message: String,
        style: AppSheetStyle = .confirmation,
        confirmTitle: String = "OK",
        cancelTitle: String? = nil,
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self.init(
            title: title,
            message: message,
            style: style,
            confirmTitle: confirmTitle,
            cancelTitle: cancelTitle,
            content: { EmptyView() },
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }
}

extension View {
    func appSheet(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        style: AppSheetStyle = .confirmation,
        confirmTitle: String = "OK",
        cancelTitle: String? = nil,
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) -> some View {
        sheet(isPresented: isPresented) {
            AppSheet(
                title: title,
                message: message,
                style: style,
                confirmTitle: confirmTitle,
                cancelTitle: cancelTitle,
                onConfirm: onConfirm,
                onCancel: onCancel
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            #if os(iOS)
            .presentationCornerRadius(28)
            #endif
        }
    }

    func appSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        style: AppSheetStyle = .confirmation,
        confirmTitle: String = "OK",
        cancelTitle: String? = nil,
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        sheet(isPresented: isPresented) {
            AppSheet(
                title: title,
                message: message,
                style: style,
                confirmTitle: confirmTitle,
                cancelTitle: cancelTitle,
                content: content,
                onConfirm: onConfirm,
                onCancel: onCancel
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            #if os(iOS)
            .presentationCornerRadius(28)
            #endif
        }
    }
}
