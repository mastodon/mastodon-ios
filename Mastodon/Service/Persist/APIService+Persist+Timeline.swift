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
            let toots = response.value
            let _ = toots.map {
                let userProperty = MastodonUser.Property(id: $0.account.id, domain: domain, acct: $0.account.acct, username: $0.account.username, displayName: $0.account.displayName,avatar: $0.account.avatar,avatarStatic: $0.account.avatarStatic, createdAt: $0.createdAt, networkDate: $0.createdAt)
                let author = MastodonUser.insert(into: managedObjectContext, property: userProperty)
                let metions = $0.mentions?.compactMap({ (mention) -> Mention in
                    Mention.insert(into: managedObjectContext, property: Mention.Property(id: mention.id, username: mention.username, acct: mention.acct, url: mention.url))
                })
                let emojis = $0.emojis?.compactMap({ (emoji) -> Emoji in
                    Emoji.insert(into: managedObjectContext, property: Emoji.Property(shortcode: emoji.shortcode, url: emoji.url, staticURL: emoji.staticURL, visibleInPicker: emoji.visibleInPicker, category: emoji.category))
                })
                
                let tags = $0.tags?.compactMap({ (tag) -> Tag in
                    let histories = tag.history?.compactMap({ (history) -> History in
                        History.insert(into: managedObjectContext, property: History.Property(day: history.day, uses: history.uses, accounts: history.accounts))
                    })
                    return Tag.insert(into: managedObjectContext, property: Tag.Property(name: tag.name, url: tag.url, histories: histories))
                })
                let tootProperty = Toot.Property(
                    domain: domain,
                    id: $0.id,
                    uri: $0.uri,
                    createdAt: $0.createdAt,
                    content: $0.content,
                    visibility: $0.visibility?.rawValue,
                    sensitive: $0.sensitive ?? false,
                    spoilerText: $0.spoilerText,
                    mentions: metions,
                    emojis: emojis,
                    tags: tags,
                    reblogsCount: NSNumber(value: $0.reblogsCount),
                    favouritesCount: NSNumber(value: $0.favouritesCount),
                    repliesCount: ($0.repliesCount != nil) ? NSNumber(value: $0.repliesCount!) : nil,
                    url: $0.uri,
                    inReplyToID: $0.inReplyToID,
                    inReplyToAccountID: $0.inReplyToAccountID,
                    reblog: nil,   //TODO need fix
                    language: $0.language,
                    text: $0.text,
                    favouritedBy: ($0.favourited ?? false) ? author : nil,
                    rebloggedBy: ($0.reblogged ?? false) ? author : nil,
                    mutedBy: ($0.muted ?? false) ? author : nil,
                    bookmarkedBy: ($0.bookmarked ?? false) ? author : nil,
                    pinnedBy: ($0.pinned ?? false) ? author : nil,
                    updatedAt: response.networkDate,
                    deletedAt: nil,
                    author: author,
                    homeTimelineIndexes: nil)
                Toot.insert(into: managedObjectContext, property: tootProperty, author: author)
            }
        }.eraseToAnyPublisher()
    }
}
