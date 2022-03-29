//
//  MastodonPoll.swift
//
//
//  Created by MainasuK on 2021-12-9.
//

import Foundation
import CoreDataStack
import MastodonSDK

extension Poll.Property {
    public init(
        entity: Mastodon.Entity.Poll,
        domain: String,
        networkDate: Date
    ) {
        self.init(
            domain: domain,
            id: entity.id,
            expiresAt: entity.expiresAt,
            expired: entity.expired,
            multiple: entity.multiple,
            votesCount: Int64(entity.votesCount),
            votersCount: Int64(entity.votersCount ?? 0),
            createdAt: networkDate,
            updatedAt: networkDate
        )
    }
}
