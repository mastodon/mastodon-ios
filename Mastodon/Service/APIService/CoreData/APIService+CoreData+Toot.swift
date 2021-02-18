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
    
    static func createOrMergeToot(
        into managedObjectContext: NSManagedObjectContext,
        for requestMastodonUser: MastodonUser?,
        entity: Mastodon.Entity.Status,
        domain: String,
        networkDate: Date,
        log: OSLog
    ) -> (Toot: Toot, isTootCreated: Bool, isMastodonUserCreated: Bool) {

        // build tree
        let reblog = entity.reblog.flatMap { entity -> Toot in
            let (toot, _, _) = createOrMergeToot(into: managedObjectContext, for: requestMastodonUser, entity: entity, domain: domain, networkDate: networkDate, log: log)
            return toot
        }
        
        // fetch old Toot
        let oldToot: Toot? = {
            let request = Toot.sortedFetchRequest
            request.predicate = Toot.predicate(domain: domain, id: entity.id)
            request.fetchLimit = 1
            request.returnsObjectsAsFaults = false
            do {
                return try managedObjectContext.fetch(request).first
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }()

        if let oldToot = oldToot {
            // merge old Toot
            APIService.CoreData.mergeToot(for: requestMastodonUser, old: oldToot,in: domain, entity: entity, networkDate: networkDate)
            return (oldToot, false, false)
        } else {
            let (mastodonUser, isMastodonUserCreated) = createOrMergeMastodonUser(into: managedObjectContext, for: requestMastodonUser,in: domain, entity: entity.account, networkDate: networkDate, log: log)
            let application = entity.application.flatMap { app -> Application? in
                Application.insert(into: managedObjectContext, property: Application.Property(name: app.name, website: app.website, vapidKey: app.vapidKey))
            }
            let metions = entity.mentions?.compactMap { mention -> Mention in
                Mention.insert(into: managedObjectContext, property: Mention.Property(id: mention.id, username: mention.username, acct: mention.acct, url: mention.url))
            }
            let emojis = entity.emojis?.compactMap { emoji -> Emoji in
                Emoji.insert(into: managedObjectContext, property: Emoji.Property(shortcode: emoji.shortcode, url: emoji.url, staticURL: emoji.staticURL, visibleInPicker: emoji.visibleInPicker, category: emoji.category))
            }
            let tags = entity.tags?.compactMap { tag -> Tag in
                let histories = tag.history?.compactMap({ (history) -> History in
                    History.insert(into: managedObjectContext, property: History.Property(day: history.day, uses: history.uses, accounts: history.accounts))
                })
                return Tag.insert(into: managedObjectContext, property: Tag.Property(name: tag.name, url: tag.url, histories: histories))
            }
            let tootProperty = Toot.Property(entity: entity, domain: domain, networkDate: networkDate)
            let toot = Toot.insert(
                into: managedObjectContext,
                property: tootProperty,
                author: mastodonUser,
                reblog: reblog,
                application: application,
                mentions: metions,
                emojis: emojis,
                tags: tags,
                favouritedBy: (entity.favourited ?? false) ? requestMastodonUser : nil,
                rebloggedBy: (entity.reblogged ?? false) ? requestMastodonUser : nil,
                mutedBy: (entity.muted ?? false) ? requestMastodonUser : nil,
                bookmarkedBy: (entity.bookmarked ?? false) ? requestMastodonUser : nil,
                pinnedBy: (entity.pinned ?? false) ? requestMastodonUser : nil
            )
            return (toot, true, isMastodonUserCreated)
        }
    }
    
    static func mergeToot(for requestMastodonUser: MastodonUser?, old toot: Toot,in domain: String, entity: Mastodon.Entity.Status, networkDate: Date) {
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
        
        if let mastodonUser = requestMastodonUser {
            if let favourited = entity.favourited {
                toot.update(liked: favourited, mastodonUser: mastodonUser)
            }
            if let reblogged = entity.reblogged {
                toot.update(reblogged: reblogged, mastodonUser: mastodonUser)
            }
            if let muted = entity.muted {
                toot.update(muted: muted, mastodonUser: mastodonUser)
            }
            if let bookmarked = entity.bookmarked {
                toot.update(bookmarked: bookmarked, mastodonUser: mastodonUser)
            }
        }
        
        
        
        
        // set updateAt
        toot.didUpdate(at: networkDate)

        // merge user
        mergeMastodonUser(for: requestMastodonUser, old: toot.author, in: domain, entity: entity.account, networkDate: networkDate)
        // merge indirect reblog & quote
        if let reblog = toot.reblog, let reblogEntity = entity.reblog {
            mergeToot(for: requestMastodonUser, old: reblog,in: domain, entity: reblogEntity, networkDate: networkDate)
        }
    }
    
}
