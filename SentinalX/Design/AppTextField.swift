//
//  AppTextField.swift
//  SentinalX
//
//  Lab 01 AppTextField, drawn with the SentinalX field chrome.
//

import SwiftUI

struct AppTextField: View {
    let title: String
    let placeholder: String

    @Binding var text: String

    var errorMessage: String? = nil
    var isSecure: Bool = false
    var systemImage: String? = nil
    var usesNumberPad: Bool = false
    var onSubmit: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SX.secondary)
            }

            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(SX.secondary)
                        .frame(width: 20)
                }
                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .foregroundStyle(SX.ink)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .keyboardType(usesNumberPad ? .numberPad : (isSecure ? .default : .emailAddress))
                #endif
                .onSubmit { onSubmit?() }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(SX.surfaceRaised, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(errorMessage == nil ? SX.stroke : SX.critical, lineWidth: 1)
            )

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(SX.critical)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title.isEmpty ? placeholder : title)
    }
}
