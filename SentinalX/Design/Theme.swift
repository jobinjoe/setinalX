//
//  Theme.swift
//  SentinalX
//

import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

enum SX {
    static let background = Color.dynamic(
        light: Color(red: 0.953, green: 0.961, blue: 0.973),
        dark: Color(red: 0.027, green: 0.035, blue: 0.055)
    )
    static let surface = Color.dynamic(
        light: Color.white,
        dark: Color(red: 0.071, green: 0.094, blue: 0.149)
    )
    static let surfaceRaised = Color.dynamic(
        light: Color(red: 0.941, green: 0.953, blue: 0.969),
        dark: Color(red: 0.047, green: 0.063, blue: 0.094)
    )
    static let ink = Color.dynamic(
        light: Color(red: 0.071, green: 0.090, blue: 0.133),
        dark: Color(red: 0.957, green: 0.969, blue: 0.984)
    )
    static let secondary = Color.dynamic(
        light: Color(red: 0.361, green: 0.420, blue: 0.510),
        dark: Color(red: 0.557, green: 0.608, blue: 0.702)
    )
    static let stroke = Color.dynamic(
        light: Color(red: 0.894, green: 0.914, blue: 0.941),
        dark: Color.white.opacity(0.10)
    )
    static let accent = Color.dynamic(
        light: Color(red: 0.047, green: 0.486, blue: 0.518),
        dark: Color(red: 0.361, green: 0.882, blue: 0.902)
    )
    static let armed = Color.dynamic(
        light: Color(red: 0.722, green: 0.431, blue: 0.0),
        dark: Color(red: 1.0, green: 0.690, blue: 0.125)
    )
    static let safe = Color.dynamic(
        light: Color(red: 0.047, green: 0.478, blue: 0.286),
        dark: Color(red: 0.239, green: 0.863, blue: 0.592)
    )
    static let critical = Color.dynamic(
        light: Color(red: 0.784, green: 0.118, blue: 0.208),
        dark: Color(red: 1.0, green: 0.361, blue: 0.416)
    )
    static let warning = Color.dynamic(
        light: Color(red: 0.761, green: 0.255, blue: 0.047),
        dark: Color(red: 1.0, green: 0.541, blue: 0.298)
    )

    static func labelOnFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.07, green: 0.08, blue: 0.11)
            : Color.white
    }
}

extension Color {
    static func dynamic(light: Color, dark: Color) -> Color {
        #if os(macOS)
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            let match = appearance.bestMatch(from: [.aqua, .darkAqua])
            return NSColor(match == .darkAqua ? dark : light)
        }))
        #else
        Color(uiColor: UIColor { traits in
            UIColor(traits.userInterfaceStyle == .dark ? dark : light)
        })
        #endif
    }
}

extension View {
    func sxCard(padding: CGFloat = 16) -> some View {
        modifier(SXCardModifier(padding: padding))
    }
}

private struct SXCardModifier: ViewModifier {
    var padding: CGFloat
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(SX.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(SX.stroke, lineWidth: 1)
            )
            .shadow(
                color: .black.opacity(scheme == .dark ? 0.28 : 0.06),
                radius: scheme == .dark ? 14 : 18,
                y: 8
            )
    }
}

struct ScreenBackdrop<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .scrollClipDisabled()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background {
                // The glow is decoration only. Giving it a fixed width inside
                // the same stack as the content made the whole screen wider
                // than an iPhone, which clipped both edges.
                ZStack(alignment: .top) {
                    SX.background
                    Ellipse()
                        .fill(SX.accent.opacity(0.20))
                        .frame(width: 280, height: 180)
                        .blur(radius: 50)
                        .offset(y: -90)
                        .frame(maxWidth: .infinity)
                        .allowsHitTesting(false)
                }
                .ignoresSafeArea()
            }
    }
}
