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
            header: entity.header,
            headerStatic: entity.headerStatic,
            note: entity.note,
            url: entity.url,
            emojisData: entity.emojis.flatMap { MastodonUser.encode(emojis: $0) },
            fieldsData: entity.fields.flatMap { MastodonUser.encode(fields: $0) },
            statusesCount: entity.statusesCount,
            followingCount: entity.followingCount,
            followersCount: entity.followersCount,
            locked: entity.locked,
            bot: entity.bot,
            suspended: entity.suspended,
            createdAt: entity.createdAt,
            networkDate: networkDate
        )
    }
}

extension MastodonUser: EmojiContainer { }
extension MastodonUser: FieldContainer { }
