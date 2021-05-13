//
//  Status.swift
//  CoreDataStack
//
//  Created by MainasuK Cirno on 2021/1/27.
//

import CoreData
import Foundation

public final class Status: NSManagedObject {
    public typealias ID = String
    
    @NSManaged public private(set) var identifier: ID
    @NSManaged public private(set) var domain: String
    
    @NSManaged public private(set) var id: String
    @NSManaged public private(set) var uri: String
    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var content: String
    
    @NSManaged public private(set) var visibility: String?
    @NSManaged public private(set) var sensitive: Bool
    @NSManaged public private(set) var spoilerText: String?
    @NSManaged public private(set) var application: Application?
    
    @NSManaged public private(set) var emojisData: Data?
    
    // Informational
    @NSManaged public private(set) var reblogsCount: NSNumber
    @NSManaged public private(set) var favouritesCount: NSNumber
    @NSManaged public private(set) var repliesCount: NSNumber?
    
    @NSManaged public private(set) var url: String?
    @NSManaged public private(set) var inReplyToID: Status.ID?
    @NSManaged public private(set) var inReplyToAccountID: MastodonUser.ID?
    
    @NSManaged public private(set) var language: String? //  (ISO 639 Part 1 two-letter language code)
    @NSManaged public private(set) var text: String?
    
    // many-to-one relastionship
    @NSManaged public private(set) var author: MastodonUser
    @NSManaged public private(set) var reblog: Status?
    @NSManaged public private(set) var replyTo: Status?
    
    // many-to-many relastionship
    @NSManaged public private(set) var favouritedBy: Set<MastodonUser>?
    @NSManaged public private(set) var rebloggedBy: Set<MastodonUser>?
    @NSManaged public private(set) var mutedBy: Set<MastodonUser>?
    @NSManaged public private(set) var bookmarkedBy: Set<MastodonUser>?

    // one-to-one relastionship
    @NSManaged public private(set) var pinnedBy: MastodonUser?
    @NSManaged public private(set) var poll: Poll?
        
    // one-to-many relationship
    @NSManaged public private(set) var reblogFrom: Set<Status>?
    @NSManaged public private(set) var mentions: Set<Mention>?
    @NSManaged public private(set) var tags: Set<Tag>?
    @NSManaged public private(set) var homeTimelineIndexes: Set<HomeTimelineIndex>?
    @NSManaged public private(set) var mediaAttachments: Set<Attachment>?
    @NSManaged public private(set) var replyFrom: Set<Status>?
    
    @NSManaged public private(set) var inNotifications: Set<MastodonNotification>?
    
    @NSManaged public private(set) var updatedAt: Date
    @NSManaged public private(set) var deletedAt: Date?
    @NSManaged public private(set) var revealedAt: Date?
}

extension Status {

    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        author: MastodonUser,
        reblog: Status?,
        application: Application?,
        replyTo: Status?,
        poll: Poll?,
        mentions: [Mention]?,
        tags: [Tag]?,
        mediaAttachments: [Attachment]?,
        favouritedBy: MastodonUser?,
        rebloggedBy: MastodonUser?,
        mutedBy: MastodonUser?,
        bookmarkedBy: MastodonUser?,
        pinnedBy: MastodonUser?
    ) -> Status {
        let status: Status = context.insertObject()
        
        status.identifier = property.identifier
        status.domain = property.domain
       
        status.id = property.id
        status.uri = property.uri
        status.createdAt = property.createdAt
        status.content = property.content
        
        status.visibility = property.visibility
        status.sensitive = property.sensitive
        status.spoilerText = property.spoilerText
        status.application = application
        
        status.emojisData = property.emojisData

        status.reblogsCount = property.reblogsCount
        status.favouritesCount = property.favouritesCount
        status.repliesCount = property.repliesCount
        
        status.url = property.url
        status.inReplyToID = property.inReplyToID
        status.inReplyToAccountID = property.inReplyToAccountID
        
        status.language = property.language
        status.text = property.text
        
        status.author = author
        status.reblog = reblog
        
        status.pinnedBy = pinnedBy
        status.poll = poll
        
        if let mentions = mentions {
            status.mutableSetValue(forKey: #keyPath(Status.mentions)).addObjects(from: mentions)
        }
        if let tags = tags {
            status.mutableSetValue(forKey: #keyPath(Status.tags)).addObjects(from: tags)
        }
        if let mediaAttachments = mediaAttachments {
            status.mutableSetValue(forKey: #keyPath(Status.mediaAttachments)).addObjects(from: mediaAttachments)
        }
        if let favouritedBy = favouritedBy {
            status.mutableSetValue(forKey: #keyPath(Status.favouritedBy)).add(favouritedBy)
        }
        if let rebloggedBy = rebloggedBy {
            status.mutableSetValue(forKey: #keyPath(Status.rebloggedBy)).add(rebloggedBy)
        }
        if let mutedBy = mutedBy {
            status.mutableSetValue(forKey: #keyPath(Status.mutedBy)).add(mutedBy)
        }
        if let bookmarkedBy = bookmarkedBy {
            status.mutableSetValue(forKey: #keyPath(Status.bookmarkedBy)).add(bookmarkedBy)
        }
        
        status.updatedAt = property.networkDate
        
        return status
    }
    
    public func update(emojisData: Data?) {
        if self.emojisData != emojisData {
            self.emojisData = emojisData
        }
    }
    
    public func update(reblogsCount: NSNumber) {
        if self.reblogsCount.intValue != reblogsCount.intValue {
            self.reblogsCount = reblogsCount
        }
    }
    
    public func update(favouritesCount: NSNumber) {
        if self.favouritesCount.intValue != favouritesCount.intValue {
            self.favouritesCount = favouritesCount
        }
    }
    
    public func update(repliesCount: NSNumber?) {
        guard let count = repliesCount else {
            return
        }
        if self.repliesCount?.intValue != count.intValue {
            self.repliesCount = repliesCount
        }
    }
    
    public func update(replyTo: Status?) {
        if self.replyTo != replyTo {
            self.replyTo = replyTo
        }
    }
    
    public func update(liked: Bool, by mastodonUser: MastodonUser) {
        if liked {
            if !(self.favouritedBy ?? Set()).contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(Status.favouritedBy)).add(mastodonUser)
            }
        } else {
            if (self.favouritedBy ?? Set()).contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(Status.favouritedBy)).remove(mastodonUser)
            }
        }
    }
    
    public func update(reblogged: Bool, by mastodonUser: MastodonUser) {
        if reblogged {
            if !(self.rebloggedBy ?? Set()).contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(Status.rebloggedBy)).add(mastodonUser)
            }
        } else {
            if (self.rebloggedBy ?? Set()).contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(Status.rebloggedBy)).remove(mastodonUser)
            }
        }
    }
    
    public func update(muted: Bool, by mastodonUser: MastodonUser) {
        if muted {
            if !(self.mutedBy ?? Set()).contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(Status.mutedBy)).add(mastodonUser)
            }
        } else {
            if (self.mutedBy ?? Set()).contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(Status.mutedBy)).remove(mastodonUser)
            }
        }
    }
    
    public func update(bookmarked: Bool, by mastodonUser: MastodonUser) {
        if bookmarked {
            if !(self.bookmarkedBy ?? Set()).contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(Status.bookmarkedBy)).add(mastodonUser)
            }
        } else {
            if (self.bookmarkedBy ?? Set()).contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(Status.bookmarkedBy)).remove(mastodonUser)
            }
        }
    }
    
    public func update(isReveal: Bool) {
        revealedAt = isReveal ? Date() : nil
    }
    
    public func didUpdate(at networkDate: Date) {
        self.updatedAt = networkDate
    }

}

extension Status {
    public struct Property {
        
        public let identifier: ID
        public let domain: String
        
        public let id: String
        public let uri: String
        public let createdAt: Date
        public let content: String
        
        public let visibility: String?
        public let sensitive: Bool
        public let spoilerText: String?
        
        public let emojisData: Data?
        
        public let reblogsCount: NSNumber
        public let favouritesCount: NSNumber
        public let repliesCount: NSNumber?
        
        public let url: String?
        public let inReplyToID: Status.ID?
        public let inReplyToAccountID: MastodonUser.ID?
        public let language: String? //  (ISO 639 Part @1 two-letter language code)
        public let text: String?
                
        public let networkDate: Date
        
        public init(
            domain: String,
            id: String,
            uri: String,
            createdAt: Date,
            content: String,
            visibility: String?,
            sensitive: Bool,
            spoilerText: String?,
            emojisData: Data?,
            reblogsCount: NSNumber,
            favouritesCount: NSNumber,
            repliesCount: NSNumber?,
            url: String?,
            inReplyToID: Status.ID?,
            inReplyToAccountID: MastodonUser.ID?,
            language: String?,
            text: String?,
            networkDate: Date
        ) {
            self.identifier = id + "@" + domain
            self.domain = domain
            self.id = id
            self.uri = uri
            self.createdAt = createdAt
            self.content = content
            self.visibility = visibility
            self.sensitive = sensitive
            self.spoilerText = spoilerText
            self.emojisData = emojisData
            self.reblogsCount = reblogsCount
            self.favouritesCount = favouritesCount
            self.repliesCount = repliesCount
            self.url = url
            self.inReplyToID = inReplyToID
            self.inReplyToAccountID = inReplyToAccountID
            self.language = language
            self.text = text
            self.networkDate = networkDate
        }
        
    }
}

extension Status: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \Status.createdAt, ascending: false)]
    }
}

extension Status {
    
    static func predicate(domain: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(Status.domain), domain)
    }
    
    static func predicate(id: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(Status.id), id)
    }
    
    public static func predicate(domain: String, id: String) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            predicate(domain: domain),
            predicate(id: id)
        ])
    }
    
    static func predicate(ids: [String]) -> NSPredicate {
        return NSPredicate(format: "%K IN %@", #keyPath(Status.id), ids)
    }
    
    public static func predicate(domain: String, ids: [String]) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            predicate(domain: domain),
            predicate(ids: ids)
        ])
    }
    
    public static func notDeleted() -> NSPredicate {
        return NSPredicate(format: "%K == nil", #keyPath(Status.deletedAt))
    }
    
    public static func deleted() -> NSPredicate {
        return NSPredicate(format: "%K != nil", #keyPath(Status.deletedAt))
    }
    
}
