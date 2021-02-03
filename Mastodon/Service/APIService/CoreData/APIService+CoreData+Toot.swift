//
//  APIService+CoreData+Toot.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/3.
//

import Foundation
import CoreData
import CoreDataStack
import CommonOSLog
import MastodonSDK

extension APIService.CoreData {
    
    static func createOrMergeTweet(
        into managedObjectContext: NSManagedObjectContext,
        for requestMastodonUser: MastodonUser,
        entity: Mastodon.Entity.Toot,
        domain: String,
        networkDate: Date,
        log: OSLog
    ) -> (Toot: Toot, isTweetCreated: Bool, isMastodonUserCreated: Bool) {

        // build tree
        let reblog = entity.reblog.flatMap { entity -> Toot in
            let (toot, _, _) = createOrMergeTweet(into: managedObjectContext, for: requestMastodonUser, entity: entity,domain: domain, networkDate: networkDate, log: log)
            return toot
        }
        
        // fetch old Toot
        let oldTweet: Toot? = {
            let request = Toot.sortedFetchRequest
            request.predicate = Toot.predicate(idStr: entity.id)
            request.returnsObjectsAsFaults = false
            do {
                return try managedObjectContext.fetch(request).first
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }()

        if let oldTweet = oldTweet {
            // merge old Toot
            APIService.CoreData.mergeToot(for: requestMastodonUser, old: oldTweet,in: domain, entity: entity, networkDate: networkDate)
            return (oldTweet, false, false)
        } else {
            
            let (mastodonUser, isMastodonUserCreated) = createOrMergeMastodonUser(into: managedObjectContext, for: requestMastodonUser,in: domain, entity: entity.account, networkDate: networkDate, log: log)
            let application = entity.application.flatMap { (app) -> Application? in
                Application.insert(into: managedObjectContext, property: Application.Property(name: app.name, website: app.website, vapidKey: app.vapidKey))
            }
            
            let metions = entity.mentions?.compactMap({ (mention) -> Mention in
                Mention.insert(into: managedObjectContext, property: Mention.Property(id: mention.id, username: mention.username, acct: mention.acct, url: mention.url))
            })
            let emojis = entity.emojis?.compactMap({ (emoji) -> Emoji in
                Emoji.insert(into: managedObjectContext, property: Emoji.Property(shortcode: emoji.shortcode, url: emoji.url, staticURL: emoji.staticURL, visibleInPicker: emoji.visibleInPicker, category: emoji.category))
            })
            let tags = entity.tags?.compactMap({ (tag) -> Tag in
                let histories = tag.history?.compactMap({ (history) -> History in
                    History.insert(into: managedObjectContext, property: History.Property(day: history.day, uses: history.uses, accounts: history.accounts))
                })
                return Tag.insert(into: managedObjectContext, property: Tag.Property(name: tag.name, url: tag.url, histories: histories))
            })
            let tootProperty = Toot.Property(
                domain: domain,
                id: entity.id,
                uri: entity.uri,
                createdAt: entity.createdAt,
                content: entity.content,
                visibility: entity.visibility?.rawValue,
                sensitive: entity.sensitive ?? false,
                spoilerText: entity.spoilerText,
                application: application,
                mentions: metions,
                emojis: emojis,
                tags: tags,
                reblogsCount: NSNumber(value: entity.reblogsCount),
                favouritesCount: NSNumber(value: entity.favouritesCount),
                repliesCount: (entity.repliesCount != nil) ? NSNumber(value: entity.repliesCount!) : nil,
                url: entity.uri,
                inReplyToID: entity.inReplyToID,
                inReplyToAccountID: entity.inReplyToAccountID,
                reblog: reblog,
                language: entity.language,
                text: entity.text,
                favouritedBy: (entity.favourited ?? false) ? mastodonUser : nil,
                rebloggedBy: (entity.reblogged ?? false) ? mastodonUser : nil,
                mutedBy: (entity.muted ?? false) ? mastodonUser : nil,
                bookmarkedBy: (entity.bookmarked ?? false) ? mastodonUser : nil,
                pinnedBy: (entity.pinned ?? false) ? mastodonUser : nil,
                updatedAt: networkDate,
                deletedAt: nil,
                author: requestMastodonUser,
                homeTimelineIndexes: nil)
            let toot = Toot.insert(into: managedObjectContext, property: tootProperty, author: mastodonUser)
            return (toot, true, isMastodonUserCreated)
        }
    }
    static func mergeToot(for requestMastodonUser: MastodonUser?, old toot: Toot,in domain: String, entity: Mastodon.Entity.Toot, networkDate: Date) {
        guard networkDate > toot.updatedAt else { return }

        // merge
        if entity.favouritesCount != toot.favouritesCount.intValue {
            toot.update(favouritesCount:NSNumber(value: entity.favouritesCount))
        }
        if let repliesCount = entity.repliesCount {
            if (repliesCount != toot.repliesCount?.intValue) {
                toot.update(repliesCount:NSNumber(value: repliesCount))
            }
        }
        if entity.reblogsCount != toot.reblogsCount.intValue {
            toot.update(reblogsCount:NSNumber(value: entity.reblogsCount))
        }


        // set updateAt
        toot.didUpdate(at: networkDate)

        // merge user
        mergeMastodonUser(for: requestMastodonUser, old: toot.author, in: domain, entity: entity.account, networkDate: networkDate)
        // merge indirect reblog & quote
        if let reblog = entity.reblog {
            mergeToot(for: requestMastodonUser, old: toot.reblog!,in: domain, entity: reblog, networkDate: networkDate)
        }
    }
    
}
