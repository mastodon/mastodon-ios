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

extension DataSourceFacade {
    static func status(
        managedObjectContext: NSManagedObjectContext,
        status: ManagedObjectRecord<Status>,
        target: StatusTarget
    ) async -> ManagedObjectRecord<Status>? {
        return try? await managedObjectContext.perform {
            guard let object = status.object(in: managedObjectContext) else { return nil }
            return DataSourceFacade.status(status: object, target: target)
                .flatMap { ManagedObjectRecord<Status>(objectID: $0.objectID) }
        }
    }
}

extension DataSourceFacade {
    static func author(
        managedObjectContext: NSManagedObjectContext,
        status: ManagedObjectRecord<Status>,
        target: StatusTarget
    ) async -> ManagedObjectRecord<MastodonUser>? {
        return try? await managedObjectContext.perform {
            guard let object = status.object(in: managedObjectContext) else { return nil }
            return DataSourceFacade.status(status: object, target: target)
                .flatMap { $0.author }
                .flatMap { ManagedObjectRecord<MastodonUser>(objectID: $0.objectID) }
        }
    }
}

extension DataSourceFacade {
    static func status(
        status: Status,
        target: StatusTarget
    ) -> Status? {
        switch target {
        case .status:
            return status.reblog ?? status
        case .reblog:
            return status
        }
    }
}
