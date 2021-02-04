//
//  Toot.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/2/4.
//

import Foundation
import CoreDataStack
import MastodonSDK

extension Toot.Property {
    init(entity: Mastodon.Entity.Status, domain: String, networkDate: Date) {
        self.init(
            domain: domain,
            id: entity.id,
            uri: entity.uri,
            createdAt: entity.createdAt,
            content: entity.content,
            visibility: entity.visibility?.rawValue,
            sensitive: entity.sensitive ?? false,
            spoilerText: entity.spoilerText,
            reblogsCount: NSNumber(value: entity.reblogsCount),
            favouritesCount: NSNumber(value: entity.favouritesCount),
            repliesCount: (entity.repliesCount != nil) ? NSNumber(value: entity.repliesCount!) : nil,
            url: entity.uri,
            inReplyToID: entity.inReplyToID,
            inReplyToAccountID: entity.inReplyToAccountID,
            language: entity.language,
            text: entity.text,
            networkDate: networkDate
        )
    }
}
