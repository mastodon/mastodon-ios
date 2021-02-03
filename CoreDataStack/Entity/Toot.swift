//
//  Toot.swift
//  CoreDataStack
//
//  Created by MainasuK Cirno on 2021/1/27.
//

import CoreData
import Foundation

public final class Toot: NSManagedObject {
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
    
    // Informational
    @NSManaged public private(set) var reblogsCount: NSNumber
    @NSManaged public private(set) var favouritesCount: NSNumber
    @NSManaged public private(set) var repliesCount: NSNumber?
    
    @NSManaged public private(set) var url: String?
    @NSManaged public private(set) var inReplyToID: Toot.ID?
    @NSManaged public private(set) var inReplyToAccountID: MastodonUser.ID?
    
    @NSManaged public private(set) var language: String? //  (ISO 639 Part 1 two-letter language code)
    @NSManaged public private(set) var text: String?
    
    // many-to-one relastionship
    @NSManaged public private(set) var favouritedBy: MastodonUser?
    @NSManaged public private(set) var rebloggedBy: MastodonUser?
    @NSManaged public private(set) var mutedBy: MastodonUser?
    @NSManaged public private(set) var bookmarkedBy: MastodonUser?
    
    // one-to-one relastionship
    @NSManaged public private(set) var pinnedBy: MastodonUser?
    
    @NSManaged public private(set) var updatedAt: Date
    @NSManaged public private(set) var deletedAt: Date?
    
    // one-to-many relationship
    @NSManaged public private(set) var reblogFrom: Set<Toot>?
    
    // one-to-many relationship
    @NSManaged public private(set) var mentions: Set<Mention>?
    // one-to-many relationship
    @NSManaged public private(set) var emojis: Set<Emoji>?
    
    // one-to-many relationship
    @NSManaged public private(set) var tags: Set<Tag>?
    
    // many-to-one relastionship
    @NSManaged public private(set) var reblog: Toot?
    
    // many-to-one relationship
    @NSManaged public private(set) var author: MastodonUser
    
    // one-to-many relationship
    @NSManaged public private(set) var homeTimelineIndexes: Set<HomeTimelineIndex>?
}

public extension Toot {
    @discardableResult
    static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        author: MastodonUser
    ) -> Toot {
        let toot: Toot = context.insertObject()
        
        toot.identifier = property.identifier
        toot.domain = property.domain
       
        toot.id = property.id
        toot.uri = property.uri
        toot.createdAt = property.createdAt
        toot.content = property.content
        
        toot.visibility = property.visibility
        toot.sensitive = property.sensitive
        toot.spoilerText = property.spoilerText
        
        if let application = property.application {
            toot.mutableSetValue(forKey: #keyPath(Toot.application)).add(application)
        }
        if let mentions = property.mentions {
            toot.mutableSetValue(forKey: #keyPath(Toot.mentions)).addObjects(from: mentions)
        }

        if let emojis = property.emojis {
            toot.mutableSetValue(forKey: #keyPath(Toot.emojis)).addObjects(from: emojis)
        }
        
        if let tags = property.tags {
            toot.mutableSetValue(forKey: #keyPath(Toot.tags)).addObjects(from: tags)
        }

        toot.reblogsCount = property.reblogsCount
        toot.favouritesCount = property.favouritesCount
        toot.repliesCount = property.repliesCount
        
        toot.url = property.url
        toot.inReplyToID = property.inReplyToID
        toot.inReplyToAccountID = property.inReplyToAccountID
        toot.reblog = property.reblog
        toot.language = property.language
        toot.text = property.text
        
        if let favouritedBy = property.favouritedBy {
            toot.mutableSetValue(forKey: #keyPath(Toot.favouritedBy)).add(favouritedBy)
        }
        if let rebloggedBy = property.rebloggedBy {
            toot.mutableSetValue(forKey: #keyPath(Toot.rebloggedBy)).add(rebloggedBy)
        }
        if let mutedBy = property.mutedBy {
            toot.mutableSetValue(forKey: #keyPath(Toot.mutedBy)).add(mutedBy)
        }
        if let bookmarkedBy = property.bookmarkedBy {
            toot.mutableSetValue(forKey: #keyPath(Toot.bookmarkedBy)).add(bookmarkedBy)
        }
        if let pinnedBy = property.pinnedBy {
            toot.mutableSetValue(forKey: #keyPath(Toot.pinnedBy)).add(pinnedBy)
        }
        
        toot.updatedAt = property.updatedAt
        toot.deletedAt = property.deletedAt
        toot.author = property.author
        toot.content = property.content
        toot.homeTimelineIndexes = property.homeTimelineIndexes
        
        return toot
    }
}

public extension Toot {
    struct Property {
        public init(
            domain: String,
            id: String,
            uri: String,
            createdAt: Date,
            content: String,
            visibility: String?,
            sensitive: Bool,
            spoilerText: String?,
            application: Application?,
            mentions: [Mention]?,
            emojis: [Emoji]?,
            tags: [Tag]?,
            reblogsCount: NSNumber,
            favouritesCount: NSNumber,
            repliesCount: NSNumber?,
            url: String?,
            inReplyToID: Toot.ID?,
            inReplyToAccountID: MastodonUser.ID?,
            reblog: Toot?,
            language: String?,
            text: String?,
            favouritedBy: MastodonUser?,
            rebloggedBy: MastodonUser?,
            mutedBy: MastodonUser?,
            bookmarkedBy: MastodonUser?,
            pinnedBy: MastodonUser?,
            updatedAt: Date,
            deletedAt: Date?,
            author: MastodonUser,
            homeTimelineIndexes: Set<HomeTimelineIndex>?)
        {
            self.identifier = id + "@" + domain
            self.domain = domain
            self.id = id
            self.uri = uri
            self.createdAt = createdAt
            self.content = content
            self.visibility = visibility
            self.sensitive = sensitive
            self.spoilerText = spoilerText
            self.application = application
            self.mentions = mentions
            self.emojis = emojis
            self.tags = tags
            self.reblogsCount = reblogsCount
            self.favouritesCount = favouritesCount
            self.repliesCount = repliesCount
            self.url = url
            self.inReplyToID = inReplyToID
            self.inReplyToAccountID = inReplyToAccountID
            self.reblog = reblog
            self.language = language
            self.text = text
            self.favouritedBy = favouritedBy
            self.rebloggedBy = rebloggedBy
            self.mutedBy = mutedBy
            self.bookmarkedBy = bookmarkedBy
            self.pinnedBy = pinnedBy
            self.updatedAt = updatedAt
            self.deletedAt = deletedAt
            self.author = author
            self.homeTimelineIndexes = homeTimelineIndexes
        }
        
        public let identifier: ID
        public let domain: String
        
        public let id: String
        public let uri: String
        public let createdAt: Date
        public let content: String
        
        public let visibility: String?
        public let sensitive: Bool
        public let spoilerText: String?
        public let application: Application?
        
        public let mentions: [Mention]?
        public let emojis: [Emoji]?
        public let tags: [Tag]?
        public let reblogsCount: NSNumber
        public let favouritesCount: NSNumber
        public let repliesCount: NSNumber?
        
        public let url: String?
        public let inReplyToID: Toot.ID?
        public let inReplyToAccountID: MastodonUser.ID?
        public let reblog: Toot?
        public let language: String? //  (ISO 639 Part @1 two-letter language code)
        public let text: String?
        
        public let favouritedBy: MastodonUser?
        public let rebloggedBy: MastodonUser?
        public let mutedBy: MastodonUser?
        public let bookmarkedBy: MastodonUser?
        public let pinnedBy: MastodonUser?
        
        public let updatedAt: Date
        public let deletedAt: Date?
        
        public let author: MastodonUser
        
        public let homeTimelineIndexes: Set<HomeTimelineIndex>?
    }
}

extension Toot: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \Toot.createdAt, ascending: false)]
    }
}

public extension Toot {
    static func predicate(idStr: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(Toot.id), idStr)
    }
    
    static func predicate(idStrs: [String]) -> NSPredicate {
        return NSPredicate(format: "%K IN %@", #keyPath(Toot.id), idStrs)
    }
    
    static func notDeleted() -> NSPredicate {
        return NSPredicate(format: "%K == nil", #keyPath(Toot.deletedAt))
    }
    
    static func deleted() -> NSPredicate {
        return NSPredicate(format: "%K != nil", #keyPath(Toot.deletedAt))
    }
}
