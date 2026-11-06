//
//  SettingsView.swift
//  SentinalX
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var app
    @State private var showPIN = false
    @State private var confirmSignOut = false
    @State private var confirmReset = false
    @State private var confirmClear = false

    var body: some View {
        @Bindable var session = app.session

        ScreenBackdrop {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    profile
                    SettingsGroup(title: "Security") {
                        settingsButton("Change disarm PIN", subtitle: "Required before a zone or the system can stand down.", symbol: "key.fill") {
                            showPIN = true
                        }
                        SettingsDivider()
                        labeledValue("Current PIN length", value: "\(session.disarmPIN.count) digits")
                    }
                    SettingsGroup(title: "Monitoring") {
                        toggleRow("Live event feed", subtitle: "Poll JSONPlaceholder while Activity is open.", isOn: $session.liveFeedEnabled)
                        SettingsDivider()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Check every")
                                .font(.body.weight(.medium))
                                .foregroundStyle(SX.ink)
                            Picker("Check every", selection: $session.pollSeconds) {
                                Text("15s").tag(15)
                                Text("30s").tag(30)
                                Text("60s").tag(60)
                            }
                            .pickerStyle(.segmented)
                            .accessibilityLabel("Feed interval")
                        }
                        .padding(16)
                        SettingsDivider()
                        toggleRow("Haptics", subtitle: "A light tap when arming succeeds.", isOn: $session.hapticsEnabled)
                    }
                    SettingsGroup(title: "Appearance") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Theme")
                                .font(.body.weight(.medium))
                                .foregroundStyle(SX.ink)
                            Picker("Theme", selection: $session.appearance) {
                                ForEach(AppearancePreference.allCases) { option in
                                    Text(option.title).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(16)
                    }
                    SettingsGroup(title: "On this device") {
                        settingsButton("Clear activity", subtitle: "Removes saved panel and cloud events.", symbol: "trash") {
                            confirmClear = true
                        }
                        SettingsDivider()
                        settingsButton("Restore demo zones", subtitle: "Puts the six starter zones back and clears the log.", symbol: "arrow.counterclockwise") {
                            confirmReset = true
                        }
                    }
                    SettingsGroup(title: "Session") {
                        settingsButton("Sign out", subtitle: "Zones and events stay on this device.", symbol: "rectangle.portrait.and.arrow.right") {
                            confirmSignOut = true
                        }
                    }
                    about
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
                .frame(maxWidth: 820)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Settings")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .sheet(isPresented: $showPIN) {
            ChangePINSheet()
        }
        .confirmationDialog("Sign out of this panel?", isPresented: $confirmSignOut, titleVisibility: .visible) {
            Button("Sign out", role: .destructive) { app.session.signOut() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Zones and events stay on this device.")
        }
        .confirmationDialog("Restore the demo zones?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Restore", role: .destructive) { app.zones.resetDemo() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The current arming mix and the activity log will be replaced.")
        }
        .confirmationDialog("Clear the activity log?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Clear", role: .destructive) {
                Task { await app.feed.clearAndRefresh() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var profile: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(SX.accent.opacity(0.18))
                Image(systemName: "person.fill")
                    .foregroundStyle(SX.accent)
            }
            .frame(width: 54, height: 54)
            VStack(alignment: .leading, spacing: 6) {
                TextField(
                    "Operator name",
                    text: Binding(
                        get: { app.session.operatorName },
                        set: { app.session.operatorName = $0 }
                    )
                )
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(SX.ink)
                Text(app.session.email.isEmpty ? "Not signed in" : app.session.email)
                    .font(.subheadline)
                    .foregroundStyle(SX.secondary)
            }
            Spacer()
        }
        .sxCard()
    }

    private var about: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SentinalX \(appVersion)")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(SX.secondary)
            Text("Arming rules live in a pure service and are covered by XCTest. Zones and events are stored with SwiftData. The activity feed polls JSONPlaceholder with async/await.")
                .font(.footnote)
                .foregroundStyle(SX.secondary)
        }
        .padding(.horizontal, 4)
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func toggleRow(_ title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(SX.ink)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(SX.secondary)
            }
            Spacer(minLength: 12)
            Toggle(title, isOn: isOn)
                .labelsHidden()
                .tint(SX.accent)
        }
        .padding(16)
    }

    private func labeledValue(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(SX.ink)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SX.secondary)
        }
        .padding(16)
    }

    private func settingsButton(_ title: String, subtitle: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .frame(width: 22)
                    .foregroundStyle(SX.accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(SX.ink)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(SX.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SX.secondary)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }
}

private struct ChangePINSheet: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var current = ""
    @State private var newPIN = ""
    @State private var confirm = ""
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    pinField("Current PIN", text: $current)
                    pinField("New PIN", text: $newPIN)
                    pinField("Confirm new PIN", text: $confirm)
                    if let errorText {
                        Text(errorText)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(SX.critical)
                    }
                    Text("Sign-in stays “\(DemoAccess.password)”. This PIN is only used to disarm.")
                        .font(.footnote)
                        .foregroundStyle(SX.secondary)
                }
                .padding(20)
            }
            .background(SX.background)
            .navigationTitle("Change PIN")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                }
            }
        }
    }

    private func pinField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(SX.secondary)
            SecureField(title, text: text)
                .foregroundStyle(SX.ink)
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
                .padding(14)
                .background(SX.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(SX.stroke, lineWidth: 1)
                )
        }
    }

    private func save() {
        if let message = app.session.updatePIN(current: current, newPIN: newPIN, confirm: confirm) {
            errorText = message
        } else {
            dismiss()
        }
    }
}
