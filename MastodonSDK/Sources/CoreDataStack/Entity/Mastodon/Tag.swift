//
//  Tag.swift
//  CoreDataStack
//
//  Created by sxiaojian on 2021/2/1.
//

import CoreData
import Foundation

public final class Tag: NSManagedObject {
    public typealias ID = UUID
    
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var identifier: ID
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var domain: String
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var createAt: Date
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var updatedAt: Date

    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var name: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var url: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var following: Bool
    
    // one-to-one relationship

    // many-to-many relationship
    @NSManaged public private(set) var followedBy: Set<MastodonUser>

    // one-to-many relationship
    @NSManaged public private(set) var searchHistories: Set<SearchHistory>
}

extension Tag {
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @objc public var histories: [MastodonTagHistory] {
        get {
            let keyPath = #keyPath(Tag.histories)
            willAccessValue(forKey: keyPath)
            let _data = primitiveValue(forKey: keyPath) as? Data
            didAccessValue(forKey: keyPath)
            do {
                guard let data = _data else { return [] }
                let attachments = try JSONDecoder().decode([MastodonTagHistory].self, from: data)
                return attachments
            } catch {
                assertionFailure(error.localizedDescription)
                return []
            }
        }
        set {
            let keyPath = #keyPath(Tag.histories)
            let data = try? JSONEncoder().encode(newValue)
            willChangeValue(forKey: keyPath)
            setPrimitiveValue(data, forKey: keyPath)
            didChangeValue(forKey: keyPath)
        }
    }
}

extension Tag {
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> Tag {
        let object: Tag = context.insertObject()
        
        object.configure(property: property)
        
        return object
    }
}


extension Tag: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        [NSSortDescriptor(keyPath: \Tag.createAt, ascending: false)]
    }
}

public extension Tag {
    
    static func predicate(domain: String) -> NSPredicate {
        NSPredicate(format: "%K == %@", #keyPath(Tag.domain), domain)
    }
    
    static func predicate(name: String) -> NSPredicate {
        // use case-insensitive query as tags #CaN #BE #speLLed #USiNG #arbITRARy #cASe
        NSPredicate(format: "%K MATCHES[c] %@", #keyPath(Tag.name), name)
    }
    
    static func predicate(domain: String, following: Bool) -> NSPredicate {
        NSPredicate(format: "%K == %@ AND %K == %d", #keyPath(Tag.domain), domain, #keyPath(Tag.following), following)
    }
    
    static func predicate(followedBy user: MastodonUser) -> NSPredicate {
        NSPredicate(format: "ANY %K.%K == %@", #keyPath(Tag.followedBy), #keyPath(MastodonUser.id), user.id)
    }
    
    static func predicate(domain: String, name: String) -> NSPredicate {
        NSCompoundPredicate(andPredicateWithSubpredicates: [
            predicate(domain: domain),
            predicate(name: name),
        ])
    }
    
    static func predicate(domain: String, following: Bool, by user: MastodonUser) -> NSPredicate {
        NSCompoundPredicate(andPredicateWithSubpredicates: [
            predicate(domain: domain, following: following),
            predicate(followedBy: user)
        ])
    }
}

// MARK: - AutoGenerateProperty
extension Tag: AutoGenerateProperty {
    // sourcery:inline:Tag.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
        public let identifier: ID
        public let domain: String
        public let createAt: Date
        public let updatedAt: Date
        public let name: String
        public let url: String
        public let following: Bool
        public let histories: [MastodonTagHistory]

    	public init(
    		identifier: ID,
    		domain: String,
    		createAt: Date,
    		updatedAt: Date,
    		name: String,
    		url: String,
    		following: Bool,
    		histories: [MastodonTagHistory]
    	) {
    		self.identifier = identifier
    		self.domain = domain
    		self.createAt = createAt
    		self.updatedAt = updatedAt
    		self.name = name
    		self.url = url
    		self.following = following
    		self.histories = histories
    	}
    }

    public func configure(property: Property) {
    	self.identifier = property.identifier
    	self.domain = property.domain
    	self.createAt = property.createAt
    	self.updatedAt = property.updatedAt
    	self.name = property.name
    	self.url = property.url
    	self.following = property.following
    	self.histories = property.histories
    }

    public func update(property: Property) {
    	update(updatedAt: property.updatedAt)
    	update(url: property.url)
    	update(following: property.following)
    	update(histories: property.histories)
    }
    // sourcery:end
}

// MARK: - AutoUpdatableObject
extension Tag: AutoUpdatableObject {
    // sourcery:inline:Tag.AutoUpdatableObject

    // Generated using Sourcery
    // DO NOT EDIT
    public func update(updatedAt: Date) {
    	if self.updatedAt != updatedAt {
    		self.updatedAt = updatedAt
    	}
    }
    public func update(url: String) {
    	if self.url != url {
    		self.url = url
    	}
    }
    public func update(following: Bool) {
    	if self.following != following {
    		self.following = following
    	}
    }
    public func update(histories: [MastodonTagHistory]) {
    	if self.histories != histories {
    		self.histories = histories
    	}
    }
    // sourcery:end
    
    public func update(followed: Bool, by mastodonUser: MastodonUser) {
        if following {
            if !self.followedBy.contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(Tag.followedBy)).add(mastodonUser)
            }
        } else {
            if self.followedBy.contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(Tag.followedBy)).remove(mastodonUser)
            }
        }
    }
    
}
    

extension Tag {
    
    public func findSearchHistory(domain: String, userID: MastodonUser.ID) -> SearchHistory? {
        return searchHistories.first { searchHistory in
            return searchHistory.domain == domain
            && searchHistory.userID == userID
        }
    }
    
    public func findSearchHistory(for user: MastodonUser) -> SearchHistory? {
        return searchHistories.first { searchHistory in
            return searchHistory.domain == user.domain
                && searchHistory.userID == user.id
        }
    }
    
}

public extension Tag {
//    func updateHistory(index: Int, day: Date, uses: String, account: String) {
//        let histories = self.histories.sorted {
//            $0.createAt.compare($1.createAt) == .orderedAscending
//        }
//        guard index < histories.count else { return }
//        let history = histories[index]
//        history.update(day: day)
//        history.update(uses: uses)
//        history.update(accounts: account)
//    }
//
//    func appendHistory(history: History) {
//        self.mutableSetValue(forKeyPath: #keyPath(Tag.histories)).add(history)
//    }
//
//    func update(url: String) {
//        if self.url != url {
//            self.url = url
//        }
//    }
}
