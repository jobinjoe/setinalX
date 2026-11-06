//
//  MainShellView.swift
//  SentinalX
//

import SwiftUI

struct MainShellView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        tabs
            .modifier(PhoneOrPadTabs(usesSidebar: sizeClass == .regular))
            .modifier(SuccessHaptic(tick: app.zones.feedbackTick, enabled: app.session.hapticsEnabled))
    }

    private var tabs: some View {
        TabView {
            Tab("Zones", systemImage: "shield.lefthalf.filled") {
                NavigationStack {
                    ZoneListView()
                        .navigationDestination(for: UUID.self) { id in
                            ZoneDetailView(zoneID: id)
                        }
                }
            }
            Tab("Activity", systemImage: "dot.radiowaves.left.and.right") {
                NavigationStack {
                    EventFeedView()
                }
            }
            Tab("Settings", systemImage: "slider.horizontal.3") {
                NavigationStack {
                    SettingsView()
                }
            }
        }
    }
}

/// Bottom tabs on iPhone. The sidebar style is for iPad and Mac, where there
/// is room for it. On a phone it steals horizontal space and clips the pages.
private struct PhoneOrPadTabs: ViewModifier {
    var usesSidebar: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if usesSidebar {
            content.tabViewStyle(.sidebarAdaptable)
        } else {
            content.tabViewStyle(.automatic)
        }
    }
}
