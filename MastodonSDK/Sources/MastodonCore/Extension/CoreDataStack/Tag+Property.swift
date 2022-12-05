//
//  Tag+Property.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-20.
//

import Foundation
import CoreDataStack
import MastodonSDK

extension Tag.Property {
    public init(
        entity: Mastodon.Entity.Tag,
        domain: String,
        networkDate: Date
    ) {
        self.init(
            identifier: UUID(),
            domain: domain,
            createAt: networkDate,
            updatedAt: networkDate,
            name: entity.name,
            url: entity.url,
            following: entity.following ?? false,
            histories: {
                guard let histories = entity.history else { return [] }
                let result: [MastodonTagHistory] = histories.map { history in
                    return MastodonTagHistory(entity: history)
                }
                return result
            }()
        )
    }
}

extension MastodonTagHistory {
    public convenience init(entity: Mastodon.Entity.History) {
        self.init(
            day: entity.day,
            uses: entity.uses,
            accounts: entity.accounts
        )
    }
}
