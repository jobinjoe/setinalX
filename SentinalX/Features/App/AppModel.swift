//
//  AppModel.swift
//  SentinalX
//

import Foundation
import Observation
import SwiftData

/// Composition root. Views talk to this object; it owns the stores and the
/// concrete network client.
@MainActor
@Observable
final class AppModel {
    let container: ModelContainer
    let session: SessionStore
    let log: EventLog
    let zones: ZoneBoardModel
    let feed: EventFeedModel

    init(container: ModelContainer, client: any EventFeedClient = JSONPlaceholderClient(), defaults: UserDefaults = .standard) {
        self.container = container
        let context = container.mainContext
        let session = SessionStore(defaults: defaults)
        let log = EventLog(context: context)
        let zones = ZoneBoardModel(
            store: ZoneStore(context: context),
            eventLog: log,
            session: session
        )
        self.session = session
        self.log = log
        self.zones = zones
        self.feed = EventFeedModel(log: log, client: client, zones: zones, session: session)
    }

    static func preview() -> AppModel {
        let model = AppModel(
            container: AppPersistence.make(inMemory: true),
            client: PreviewEventClient(),
            defaults: UserDefaults(suiteName: "SentinalX.preview") ?? .standard
        )
        model.zones.prepare()
        model.session.isAuthenticated = true
        return model
    }
}
