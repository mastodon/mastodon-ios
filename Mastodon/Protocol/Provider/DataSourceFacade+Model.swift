//
//  DataSourceFacade+Model.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-13.
//

import Foundation
import CoreData
import CoreDataStack
import MastodonUI
import MastodonSDK

extension DataSourceFacade {
    static func status(
        managedObjectContext: NSManagedObjectContext,
        status: MastodonStatus,
        target: StatusTarget
    ) -> MastodonStatus? {
        switch target {
        case .status:
            return status.reblog ?? status
        case .reblog:
            return status
        }
    }
}

extension DataSourceFacade {
    static func author(
        managedObjectContext: NSManagedObjectContext,
        status: MastodonStatus,
        target: StatusTarget
    ) async -> ManagedObjectRecord<MastodonUser>? {
        return try? await managedObjectContext.perform {
            return DataSourceFacade.status(managedObjectContext: managedObjectContext, status: status, target: target)
                .flatMap { $0.entity.account }
                .flatMap {
                    MastodonUser.findOrFetch(in: managedObjectContext, matching: MastodonUser.predicate(domain: $0.domain ?? "", id: $0.id))?.asRecord
                }
        }
    }
}
