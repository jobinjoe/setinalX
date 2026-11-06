//
//  SentinalXApp.swift
//  SentinalX
//

import SwiftData
import SwiftUI

@main
struct SentinalXApp: App {
    private let container = AppPersistence.container

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
        }
        .modelContainer(container)
    }
}
