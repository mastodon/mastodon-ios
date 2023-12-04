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
