//
//  MastodonUser.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/2/3.
//

import Foundation
import CoreDataStack
import MastodonSDK

extension MastodonUser.Property {
    init(entity: Mastodon.Entity.Account, domain: String, networkDate: Date) {
        self.init(
            id: entity.id,
            domain: domain,
            acct: entity.acct,
            username: entity.username,
            displayName: entity.displayName,
            avatar: entity.avatar,
            avatarStatic: entity.avatarStatic,
            createdAt: entity.createdAt,
            networkDate: networkDate
        )
    }
}

extension MastodonUser {
    public func avatarImageURL() -> URL? {
        return URL(string: avatar)
    }
}
