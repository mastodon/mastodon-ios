//
//  APIService+Persist+Timeline.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/27.
//

import os.log
import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService.Persist {
    enum PersistTimelineType {
        case publicHomeTimeline
    }
    static func persistTimeline(
        domain: String,
        managedObjectContext: NSManagedObjectContext,
        response: Mastodon.Response.Content<[Mastodon.Entity.Toot]>,
        persistType: PersistTimelineType
    ) -> AnyPublisher<Result<Void, Error>, Never> {
        return managedObjectContext.performChanges {
            let toot = response.value
            let _ = toot.map {
                let userProperty = MastodonUser.Property(id: $0.account.id, domain: domain, acct: $0.account.acct, username: $0.account.username, displayName: $0.account.displayName,avatar: $0.account.avatar,avatarStatic: $0.account.avatarStatic, createdAt: $0.createdAt, networkDate: $0.createdAt)
                let author = MastodonUser.insert(into: managedObjectContext, property: userProperty)
                let metions = $0.mentions?.compactMap({ (mention) -> Mention in
                    Mention.insert(into: managedObjectContext, property: Mention.Property(id: mention.id, username: mention.username, acct: mention.acct, url: mention.url))
                })
                let emojis = $0.emojis?.compactMap({ (emoji) -> Emoji in
                    Emoji.insert(into: managedObjectContext, property: Emoji.Property(shortcode: emoji.shortcode, url: emoji.url, staticURL: emoji.staticURL, visibleInPicker: emoji.visibleInPicker))
                })
                let tootProperty = Toot.Property(
                    domain: domain,
                    id: $0.id,
                    uri: $0.uri,
                    createdAt: $0.createdAt,
                    content: $0.content,
                    visibility: $0.visibility,
                    sensitive: $0.sensitive ?? false,
                    spoilerText: $0.spoilerText,
                    mentions: metions,
                    emojis: emojis,
                    reblogsCount: $0.reblogsCount,
                    favouritesCount: $0.favouritesCount,
                    repliesCount: $0.repliesCount ?? 0,
                    url: $0.uri,
                    inReplyToID: $0.inReplyToID,
                    inReplyToAccountID: $0.inReplyToAccountID,
                    reblog: nil,   //TODO 需要递归调用
                    language: $0.language,
                    text: $0.text,
                    favourited: $0.favourited ?? false,
                    reblogged: $0.reblogged ?? false,
                    muted: $0.muted ?? false,
                    bookmarked: $0.bookmarked ?? false,
                    pinned: $0.pinned ?? false,
                    updatedAt: response.networkDate,
                    deletedAt: nil,
                    author: author,
                    homeTimelineIndexes: nil)
                Toot.insert(into: managedObjectContext, property: tootProperty, author: author)
            }
        }.eraseToAnyPublisher()
    }
}
