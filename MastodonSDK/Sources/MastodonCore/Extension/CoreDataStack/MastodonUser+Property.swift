//
//  MastodonUser+Property.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-11.
//

import Foundation
import CoreDataStack
import MastodonSDK

extension MastodonUser.Property {
    public init(entity: Mastodon.Entity.Account, domain: String) {
        self.init(entity: entity, domain: domain, networkDate: Date())
    }
    
    init(entity: Mastodon.Entity.Account, domain: String, networkDate: Date) {
        self.init(
            identifier: entity.id + "@" + domain,
            domain: domain,
            id: entity.id,
            acct: entity.acct,
            username: entity.username,
            displayName: entity.displayName,
            avatar: entity.avatar,
            avatarStatic: entity.avatarStatic,
            header: entity.header,
            headerStatic: entity.headerStatic,
            note: entity.note,
            url: entity.url,
            statusesCount: Int64(entity.statusesCount),
            followingCount: Int64(entity.followingCount),
            followersCount: Int64(entity.followersCount),
            locked: entity.locked,
            bot: entity.bot ?? false,
            suspended: entity.suspended ?? false,
            createdAt: entity.createdAt,
            updatedAt: networkDate,
            emojis: entity.mastodonEmojis,
            fields: entity.mastodonFields
        )
    }
}
