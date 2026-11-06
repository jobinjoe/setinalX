//
//  AppPersistence.swift
//  SentinalX
//

import Foundation
import SwiftData

enum AppPersistence {
    static let container: ModelContainer = make(inMemory: false)

    static func make(inMemory: Bool) -> ModelContainer {
        let schema = Schema([ZoneRecord.self, EventRecord.self])
        let configuration = ModelConfiguration(
            "SentinalX",
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Could not open the SentinalX store: \(error)")
        }
    }
}
