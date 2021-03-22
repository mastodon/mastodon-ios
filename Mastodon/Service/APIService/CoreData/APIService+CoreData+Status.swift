//
//  APIService+CoreData+Status.swift
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
    
    static func createOrMergeStatus(
        into managedObjectContext: NSManagedObjectContext,
        for requestMastodonUser: MastodonUser?,
        domain: String,
        entity: Mastodon.Entity.Status,
        tootCache: APIService.Persist.PersistCache<Toot>?,
        userCache: APIService.Persist.PersistCache<MastodonUser>?,
        networkDate: Date,
        log: OSLog
    ) -> (Toot: Toot, isTootCreated: Bool, isMastodonUserCreated: Bool) {
        let processEntityTaskSignpostID = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: "update database - process entity: createOrMergeToot", signpostID: processEntityTaskSignpostID, "process toot %{public}s", entity.id)
        defer {
            os_signpost(.end, log: log, name: "update database - process entity: createOrMergeToot", signpostID: processEntityTaskSignpostID, "process toot %{public}s", entity.id)
        }
        
        // build tree
        let reblog = entity.reblog.flatMap { entity -> Toot in
            let (toot, _, _) = createOrMergeStatus(
                into: managedObjectContext,
                for: requestMastodonUser,
                domain: domain,
                entity: entity,
                tootCache: tootCache,
                userCache: userCache,
                networkDate: networkDate,
                log: log
            )
            return toot
        }
        
        // fetch old Toot
        let oldToot: Toot? = {
            if let tootCache = tootCache {
                return tootCache.dictionary[entity.id]
            } else {
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
            }
        }()

        if let oldToot = oldToot {
            // merge old Toot
            APIService.CoreData.merge(toot: oldToot, entity: entity, requestMastodonUser: requestMastodonUser, domain: domain, networkDate: networkDate)
            return (oldToot, false, false)
        } else {
            let (mastodonUser, isMastodonUserCreated) = createOrMergeMastodonUser(into: managedObjectContext, for: requestMastodonUser,in: domain, entity: entity.account, userCache: userCache, networkDate: networkDate, log: log)
            let application = entity.application.flatMap { app -> Application? in
                Application.insert(into: managedObjectContext, property: Application.Property(name: app.name, website: app.website, vapidKey: app.vapidKey))
            }
            let replyTo: Toot? = {
                // could be nil if target replyTo toot's persist task in the queue
                guard let inReplyToID = entity.inReplyToID,
                      let replyTo = tootCache?.dictionary[inReplyToID] else { return nil }
                return replyTo
            }()
            let poll = entity.poll.flatMap { poll -> Poll in
                let options = poll.options.enumerated().map { i, option -> PollOption in
                    let votedBy: MastodonUser? = (poll.ownVotes ?? []).contains(i) ? requestMastodonUser : nil
                    return PollOption.insert(into: managedObjectContext, property: PollOption.Property(index: i, title: option.title, votesCount: option.votesCount, networkDate: networkDate), votedBy: votedBy)
                }
                let votedBy: MastodonUser? = (poll.voted ?? false) ? requestMastodonUser : nil
                let object = Poll.insert(into: managedObjectContext, property: Poll.Property(id: poll.id, expiresAt: poll.expiresAt, expired: poll.expired, multiple: poll.multiple, votesCount: poll.votesCount, votersCount: poll.votersCount, networkDate: networkDate), votedBy: votedBy, options: options)
                return object
            }
            let metions = entity.mentions?.compactMap { mention -> Mention in
                Mention.insert(into: managedObjectContext, property: Mention.Property(id: mention.id, username: mention.username, acct: mention.acct, url: mention.url))
            }
            let emojis = entity.emojis?.compactMap { emoji -> Emoji in
                Emoji.insert(into: managedObjectContext, property: Emoji.Property(shortcode: emoji.shortcode, url: emoji.url, staticURL: emoji.staticURL, visibleInPicker: emoji.visibleInPicker, category: emoji.category))
            }
            let tags = entity.tags?.compactMap { tag -> Tag in
                let histories = tag.history?.compactMap { history -> History in
                    History.insert(into: managedObjectContext, property: History.Property(day: history.day, uses: history.uses, accounts: history.accounts))
                }
                return Tag.insert(into: managedObjectContext, property: Tag.Property(name: tag.name, url: tag.url, histories: histories))
            }
            let mediaAttachments: [Attachment]? = {
                let encoder = JSONEncoder()
                var attachments: [Attachment] = []
                for (index, attachment) in (entity.mediaAttachments ?? []).enumerated() {
                    let metaData = attachment.meta.flatMap { meta in
                        try? encoder.encode(meta)
                    }
                    let property = Attachment.Property(domain: domain, index: index, id: attachment.id, typeRaw: attachment.type.rawValue, url: attachment.url, previewURL: attachment.previewURL, remoteURL: attachment.remoteURL, metaData: metaData, textURL: attachment.textURL, descriptionString: attachment.description, blurhash: attachment.blurhash, networkDate: networkDate)
                    attachments.append(Attachment.insert(into: managedObjectContext, property: property))
                }
                guard !attachments.isEmpty else { return nil }
                return attachments
            }()
            let tootProperty = Toot.Property(entity: entity, domain: domain, networkDate: networkDate)
            let toot = Toot.insert(
                into: managedObjectContext,
                property: tootProperty,
                author: mastodonUser,
                reblog: reblog,
                application: application,
                replyTo: replyTo,
                poll: poll,
                mentions: metions,
                emojis: emojis,
                tags: tags,
                mediaAttachments: mediaAttachments,
                favouritedBy: (entity.favourited ?? false) ? requestMastodonUser : nil,
                rebloggedBy: (entity.reblogged ?? false) ? requestMastodonUser : nil,
                mutedBy: (entity.muted ?? false) ? requestMastodonUser : nil,
                bookmarkedBy: (entity.bookmarked ?? false) ? requestMastodonUser : nil,
                pinnedBy: (entity.pinned ?? false) ? requestMastodonUser : nil
            )
            tootCache?.dictionary[entity.id] = toot
            os_signpost(.event, log: log, name: "update database - process entity: createOrMergeToot", signpostID: processEntityTaskSignpostID, "did insert new tweet %{public}s: %s", mastodonUser.identifier, entity.id)
            return (toot, true, isMastodonUserCreated)
        }
    }
    
    static func merge(
        toot: Toot,
        entity: Mastodon.Entity.Status,
        requestMastodonUser: MastodonUser?,
        domain: String,
        networkDate: Date
    ) {
        guard networkDate > toot.updatedAt else { return }

        // merge poll
        if let poll = toot.poll, let entity = entity.poll {
            merge(poll: poll, entity: entity, requestMastodonUser: requestMastodonUser, domain: domain, networkDate: networkDate)
        }
        
        // merge metrics
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
        
        // merge relationship
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
        
        // merge indirect reblog
        if let reblog = toot.reblog, let reblogEntity = entity.reblog {
            merge(toot: reblog, entity: reblogEntity, requestMastodonUser: requestMastodonUser, domain: domain, networkDate: networkDate)
        }
    }
    
}

extension APIService.CoreData {
    static func merge(
        poll: Poll,
        entity: Mastodon.Entity.Poll,
        requestMastodonUser: MastodonUser?,
        domain: String,
        networkDate: Date
    ) {
        poll.update(expiresAt: entity.expiresAt)
        poll.update(expired: entity.expired)
        poll.update(votesCount: entity.votesCount)
        poll.update(votersCount: entity.votersCount)
        requestMastodonUser.flatMap {
            poll.update(voted: entity.voted ?? false, by: $0)
        }
        
        let oldOptions = poll.options.sorted(by: { $0.index.intValue < $1.index.intValue })
        for (i, (optionEntity, option)) in zip(entity.options, oldOptions).enumerated() {
            let voted: Bool = (entity.ownVotes ?? []).contains(i)
            option.update(votesCount: optionEntity.votesCount)
            requestMastodonUser.flatMap { option.update(voted: voted, by: $0) }
            option.didUpdate(at: networkDate)
        }
        
        poll.didUpdate(at: networkDate)
    }
}
