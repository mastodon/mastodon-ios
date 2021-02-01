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
    
    // rendering
    //one to many
    @NSManaged public private(set) var mentions: Set<Mention>?
    //one to many
    @NSManaged public private(set) var emojis: Set<Emoji>?
    //one to many
    @NSManaged public private(set) var tags: [Tag]?
    // Informational
    @NSManaged public private(set) var reblogsCount: Int
    @NSManaged public private(set) var favouritesCount: Int
    @NSManaged public private(set) var repliesCount: Int
    
    @NSManaged public private(set) var url: String?
    @NSManaged public private(set) var inReplyToID: Toot.ID?
    @NSManaged public private(set) var inReplyToAccountID: MastodonUser.ID?
    @NSManaged public private(set) var reblog: Toot?
    @NSManaged public private(set) var language: String? //  (ISO 639 Part @NSManaged public private(set) varletter language code)
    @NSManaged public private(set) var text: String?
    
    @NSManaged public private(set) var favourited: Bool
    @NSManaged public private(set) var reblogged: Bool
    @NSManaged public private(set) var muted: Bool
    @NSManaged public private(set) var bookmarked: Bool
    @NSManaged public private(set) var pinned: Bool
    @NSManaged public private(set) var updatedAt: Date
    @NSManaged public private(set) var deletedAt: Date?
    
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
        
        if let mentions = property.mentions {
            toot.mutableSetValue(forKey: #keyPath(Toot.mentions)).addObjects(from: mentions)
        }

        if let emojis = property.emojis {
            toot.mutableSetValue(forKey: #keyPath(Toot.mentions)).addObjects(from: emojis)
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
        
        toot.favourited = property.favourited
        toot.reblogged = property.reblogged
        toot.muted = property.muted
        toot.bookmarked = property.bookmarked
        toot.pinned = property.pinned
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
            mentions: [Mention]?,
            emojis: [Emoji]?,
            reblogsCount: Int,
            favouritesCount: Int,
            repliesCount: Int,
            url: String?,
            inReplyToID: Toot.ID?,
            inReplyToAccountID: MastodonUser.ID?,
            reblog: Toot?,
            language: String?,
            text: String?,
            favourited: Bool,
            reblogged: Bool,
            muted: Bool,
            bookmarked: Bool,
            pinned: Bool,
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
            self.mentions = mentions
            self.emojis = emojis
            self.reblogsCount = reblogsCount
            self.favouritesCount = favouritesCount
            self.repliesCount = repliesCount
            self.url = url
            self.inReplyToID = inReplyToID
            self.inReplyToAccountID = inReplyToAccountID
            self.reblog = reblog
            self.language = language
            self.text = text
            self.favourited = favourited
            self.reblogged = reblogged
            self.muted = muted
            self.bookmarked = bookmarked
            self.pinned = pinned
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
        
        public let mentions: [Mention]?
        public let emojis: [Emoji]?
        public let reblogsCount: Int
        public let favouritesCount: Int
        public let repliesCount: Int
        
        public let url: String?
        public let inReplyToID: Toot.ID?
        public let inReplyToAccountID: MastodonUser.ID?
        public let reblog: Toot?
        public let language: String? //  (ISO 639 Part @NSManaged public private(set) varletter language public let
        public let text: String?
        
        public let favourited: Bool
        public let reblogged: Bool
        public let muted: Bool
        public let bookmarked: Bool
        public let pinned: Bool
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
