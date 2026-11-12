//
//  LoginView.swift
//  SentinalX
//

import SwiftUI

struct LoginView: View {
    @Environment(AppModel.self) private var app
    @State private var email = DemoAccess.suggestedEmail
    @State private var password = ""
    @State private var errorText: String?
    @State private var glow = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                brand
                form
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 36)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            mesh.ignoresSafeArea()
        }
    }

    private var mesh: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                Color(red: 0.03, green: 0.08, blue: 0.12),
                Color(red: 0.05, green: 0.20, blue: 0.24),
                Color(red: 0.04, green: 0.08, blue: 0.18),
                Color(red: 0.03, green: 0.07, blue: 0.12),
                Color(red: 0.10, green: 0.42, blue: 0.46),
                Color(red: 0.08, green: 0.14, blue: 0.26),
                Color(red: 0.02, green: 0.03, blue: 0.06),
                Color(red: 0.08, green: 0.16, blue: 0.14),
                Color(red: 0.05, green: 0.05, blue: 0.10)
            ]
        )
    }

    private var brand: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 108, height: 108)
                    .scaleEffect(glow ? 1.06 : 0.96)
                Circle()
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    .frame(width: 108, height: 108)
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 42, weight: .medium))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse, options: .repeating.speed(0.35))
            }
            VStack(spacing: 6) {
                Text("SENTINALX")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .tracking(3.2)
                    .foregroundStyle(Color.white.opacity(0.72))
                Text("Security, in one glance.")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("A monitoring companion for the zones on this site.")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.72))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 24)
        .onAppear { glow = true }
        .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: glow)
    }

    private var form: some View {
        AppCard(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Sign in")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(SX.ink)

                AppTextField(
                    title: "",
                    placeholder: "Email",
                    text: $email,
                    systemImage: "envelope"
                )

                AppTextField(
                    title: "",
                    placeholder: "Password",
                    text: $password,
                    isSecure: true,
                    systemImage: "lock",
                    onSubmit: submit
                )

                if let errorText {
                    Text(errorText)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(SX.critical)
                }

                AppButton(
                    title: "Sign in",
                    style: .primary,
                    systemImage: "arrow.right",
                    tint: SX.accent,
                    action: submit
                )
                .padding(.top, 4)

                AppButton(
                    title: "Use demo access",
                    style: .outlined,
                    action: fillDemo
                )

                Text("Demo · \(DemoAccess.suggestedEmail) · \(DemoAccess.password)")
                    .font(.footnote)
                    .foregroundStyle(SX.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private func fillDemo() {
        email = DemoAccess.suggestedEmail
        password = DemoAccess.password
        submit()
    }

    private func submit() {
        errorText = app.session.signIn(email: email, password: password)
    }
}
