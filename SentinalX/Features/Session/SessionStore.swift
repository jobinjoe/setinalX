//
//  SessionStore.swift
//  SentinalX
//

import Foundation
import Observation

enum DemoAccess {
    static let suggestedEmail = "operator@sentinalx.app"
    static let password = "sentinal"
    static let pin = "2468"
}

enum AppearancePreference: String, CaseIterable, Identifiable {
    case system
    case dark
    case light

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .dark: "Dark"
        case .light: "Light"
        }
    }
}

/// Sign-in, the disarm PIN, and the preferences that should survive a relaunch.
/// Zones and events live in SwiftData; this stays in UserDefaults because it
/// is device preference, not monitoring history.
@MainActor
@Observable
final class SessionStore {
    private let defaults: UserDefaults

    var isAuthenticated: Bool {
        didSet { defaults.set(isAuthenticated, forKey: Key.authenticated) }
    }

    var email: String {
        didSet { defaults.set(email, forKey: Key.email) }
    }

    var operatorName: String {
        didSet { defaults.set(operatorName, forKey: Key.name) }
    }

    var disarmPIN: String {
        didSet { defaults.set(disarmPIN, forKey: Key.pin) }
    }

    var liveFeedEnabled: Bool {
        didSet { defaults.set(liveFeedEnabled, forKey: Key.live) }
    }

    var pollSeconds: Int {
        didSet { defaults.set(pollSeconds, forKey: Key.poll) }
    }

    var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Key.haptics) }
    }

    var appearanceRaw: String {
        didSet { defaults.set(appearanceRaw, forKey: Key.appearance) }
    }

    var feedCursor: Int {
        didSet { defaults.set(feedCursor, forKey: Key.cursor) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isAuthenticated = defaults.bool(forKey: Key.authenticated)
        email = defaults.string(forKey: Key.email) ?? ""
        operatorName = defaults.string(forKey: Key.name) ?? "Operator"
        let storedPIN = defaults.string(forKey: Key.pin) ?? ""
        disarmPIN = storedPIN.isEmpty ? DemoAccess.pin : storedPIN
        liveFeedEnabled = defaults.object(forKey: Key.live) as? Bool ?? true
        pollSeconds = defaults.object(forKey: Key.poll) as? Int ?? 15
        hapticsEnabled = defaults.object(forKey: Key.haptics) as? Bool ?? true
        appearanceRaw = defaults.string(forKey: Key.appearance) ?? AppearancePreference.dark.rawValue
        feedCursor = defaults.object(forKey: Key.cursor) as? Int ?? 0
    }

    var appearance: AppearancePreference {
        get { AppearancePreference(rawValue: appearanceRaw) ?? .dark }
        set { appearanceRaw = newValue.rawValue }
    }

    var liveFeedToken: String {
        "\(liveFeedEnabled)-\(pollSeconds)"
    }

    func signIn(email: String, password: String) -> String? {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedEmail.contains("@"), trimmedEmail.contains(".") else {
            return "Enter a valid email address."
        }
        guard trimmedPassword == DemoAccess.password else {
            return "That password doesn't match the demo access."
        }
        self.email = trimmedEmail
        if operatorName == "Operator" || operatorName.isEmpty {
            let prefix = trimmedEmail.split(separator: "@").first.map(String.init) ?? "Operator"
            operatorName = prefix.capitalized
        }
        isAuthenticated = true
        return nil
    }

    func signOut() {
        isAuthenticated = false
    }

    func updatePIN(current: String, newPIN: String, confirm: String) -> String? {
        guard current.trimmingCharacters(in: .whitespacesAndNewlines) == disarmPIN else {
            return "Current PIN is incorrect."
        }
        let next = newPIN.trimmingCharacters(in: .whitespacesAndNewlines)
        guard next.count == 4, next.allSatisfy(\.isNumber) else {
            return "Use a 4-digit PIN."
        }
        guard next == confirm.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return "Those new PINs don't match."
        }
        disarmPIN = next
        return nil
    }

    private enum Key {
        static let authenticated = "sx.authenticated"
        static let email = "sx.email"
        static let name = "sx.name"
        static let pin = "sx.pin"
        static let live = "sx.live"
        static let poll = "sx.poll"
        static let haptics = "sx.haptics"
        static let appearance = "sx.appearance"
        static let cursor = "sx.cursor"
    }
}
