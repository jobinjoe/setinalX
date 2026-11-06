//
//  RootView.swift
//  SentinalX
//

import SwiftData
import SwiftUI

struct RootView: View {
    var container: ModelContainer
    @State private var appModel: AppModel?

    var body: some View {
        ZStack {
            SX.background.ignoresSafeArea()
            if let appModel {
                Group {
                    if appModel.session.isAuthenticated {
                        MainShellView()
                    } else {
                        LoginView()
                    }
                }
                .environment(appModel)
                .tint(SX.accent)
                .preferredColorScheme(colorScheme(for: appModel.session.appearance))
                .animation(.spring(duration: 0.4), value: appModel.session.isAuthenticated)
            } else {
                VStack(spacing: 14) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 36))
                        .foregroundStyle(SX.accent)
                    ProgressView()
                        .tint(SX.accent)
                }
            }
        }
        .task {
            guard appModel == nil else { return }
            let model = AppModel(container: container)
            model.zones.prepare()
            appModel = model
        }
    }

    private func colorScheme(for preference: AppearancePreference) -> ColorScheme? {
        switch preference {
        case .system: nil
        case .dark: .dark
        case .light: .light
        }
    }
}
