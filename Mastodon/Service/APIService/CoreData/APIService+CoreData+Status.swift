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
        statusCache: APIService.Persist.PersistCache<Status>?,
        userCache: APIService.Persist.PersistCache<MastodonUser>?,
        networkDate: Date,
        log: OSLog
    ) -> (status: Status, isStatusCreated: Bool, isMastodonUserCreated: Bool) {
        let processEntityTaskSignpostID = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: "update database - process entity: createOrMergeStatus", signpostID: processEntityTaskSignpostID, "process status %{public}s", entity.id)
        defer {
            os_signpost(.end, log: log, name: "update database - process entity: createOrMergeStatus", signpostID: processEntityTaskSignpostID, "process status %{public}s", entity.id)
        }
        
        // build tree
        let reblog = entity.reblog.flatMap { entity -> Status in
            let (status, _, _) = createOrMergeStatus(
                into: managedObjectContext,
                for: requestMastodonUser,
                domain: domain,
                entity: entity,
                statusCache: statusCache,
                userCache: userCache,
                networkDate: networkDate,
                log: log
            )
            return status
        }
        
        // fetch old Status
        let oldStatus: Status? = {
            if let statusCache = statusCache {
                return statusCache.dictionary[entity.id]
            } else {
                let request = Status.sortedFetchRequest
                request.predicate = Status.predicate(domain: domain, id: entity.id)
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

        if let oldStatus = oldStatus {
            // merge old Status
            APIService.CoreData.merge(status: oldStatus, entity: entity, requestMastodonUser: requestMastodonUser, domain: domain, networkDate: networkDate)
            return (oldStatus, false, false)
        } else {
            let (mastodonUser, isMastodonUserCreated) = createOrMergeMastodonUser(into: managedObjectContext, for: requestMastodonUser,in: domain, entity: entity.account, userCache: userCache, networkDate: networkDate, log: log)
            let application = entity.application.flatMap { app -> Application? in
                Application.insert(into: managedObjectContext, property: Application.Property(name: app.name, website: app.website, vapidKey: app.vapidKey))
            }
            let replyTo: Status? = {
                // could be nil if target replyTo status's persist task in the queue
                guard let inReplyToID = entity.inReplyToID,
                      let replyTo = statusCache?.dictionary[inReplyToID] else { return nil }
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
            let metions = entity.mentions?.enumerated().compactMap { index, mention -> Mention in
                Mention.insert(into: managedObjectContext, property: Mention.Property(id: mention.id, username: mention.username, acct: mention.acct, url: mention.url), index: index)
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
                    let property = Attachment.Property(domain: domain, index: index, id: attachment.id, typeRaw: attachment.type.rawValue, url: attachment.url ?? "", previewURL: attachment.previewURL, remoteURL: attachment.remoteURL, metaData: metaData, textURL: attachment.textURL, descriptionString: attachment.description, blurhash: attachment.blurhash, networkDate: networkDate)
                    attachments.append(Attachment.insert(into: managedObjectContext, property: property))
                }
                guard !attachments.isEmpty else { return nil }
                return attachments
            }()
            let statusProperty = Status.Property(entity: entity, domain: domain, networkDate: networkDate)
            let status = Status.insert(
                into: managedObjectContext,
                property: statusProperty,
                author: mastodonUser,
                reblog: reblog,
                application: application,
                replyTo: replyTo,
                poll: poll,
                mentions: metions,
                tags: tags,
                mediaAttachments: mediaAttachments,
                favouritedBy: (entity.favourited ?? false) ? requestMastodonUser : nil,
                rebloggedBy: (entity.reblogged ?? false) ? requestMastodonUser : nil,
                mutedBy: (entity.muted ?? false) ? requestMastodonUser : nil,
                bookmarkedBy: (entity.bookmarked ?? false) ? requestMastodonUser : nil,
                pinnedBy: (entity.pinned ?? false) ? requestMastodonUser : nil
            )
            statusCache?.dictionary[entity.id] = status
            os_signpost(.event, log: log, name: "update database - process entity: createOrMergeStatus", signpostID: processEntityTaskSignpostID, "did insert new tweet %{public}s: %s", mastodonUser.identifier, entity.id)
            return (status, true, isMastodonUserCreated)
        }
    }
    
}

extension APIService.CoreData {
    static func merge(
        status: Status,
        entity: Mastodon.Entity.Status,
        requestMastodonUser: MastodonUser?,
        domain: String,
        networkDate: Date
    ) {
        guard networkDate > status.updatedAt else { return }

        // merge poll
        if let poll = status.poll, let entity = entity.poll {
            merge(poll: poll, entity: entity, requestMastodonUser: requestMastodonUser, domain: domain, networkDate: networkDate)
        }
        
        // merge metrics
        if entity.favouritesCount != status.favouritesCount.intValue {
            status.update(favouritesCount:NSNumber(value: entity.favouritesCount))
        }
        if let repliesCount = entity.repliesCount {
            if (repliesCount != status.repliesCount?.intValue) {
                status.update(repliesCount:NSNumber(value: repliesCount))
            }
        }
        if entity.reblogsCount != status.reblogsCount.intValue {
            status.update(reblogsCount:NSNumber(value: entity.reblogsCount))
        }
        
        // merge relationship
        if let mastodonUser = requestMastodonUser {
            if let favourited = entity.favourited {
                status.update(liked: favourited, by: mastodonUser)
            }
            if let reblogged = entity.reblogged {
                status.update(reblogged: reblogged, by: mastodonUser)
            }
            if let muted = entity.muted {
                status.update(muted: muted, by: mastodonUser)
            }
            if let bookmarked = entity.bookmarked {
                status.update(bookmarked: bookmarked, by: mastodonUser)
            }
        }
        
        // set updateAt
        status.didUpdate(at: networkDate)

        // merge user
        merge(
            user: status.author,
            entity: entity.account,
            requestMastodonUser: requestMastodonUser,
            domain: domain,
            networkDate: networkDate
        )
        
        // merge indirect reblog
        if let reblog = status.reblog, let reblogEntity = entity.reblog {
            merge(
                status: reblog,
                entity: reblogEntity,
                requestMastodonUser: requestMastodonUser,
                domain: domain,
                networkDate: networkDate
            )
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
