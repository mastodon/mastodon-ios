//
//  Attachment.swift
//  CoreDataStack
//
//  Created by MainasuK Cirno on 2021-2-23.
//

import CoreData
import Foundation

public final class Attachment: NSManagedObject {
    public typealias ID = String
    
    @NSManaged public private(set) var id: ID
    @NSManaged public private(set) var domain: String
    @NSManaged public private(set) var typeRaw: String
    @NSManaged public private(set) var url: String
    @NSManaged public private(set) var previewURL: String?
    
    @NSManaged public private(set) var remoteURL: String?
    @NSManaged public private(set) var metaData: Data?
    @NSManaged public private(set) var textURL: String?
    @NSManaged public private(set) var descriptionString: String?
    @NSManaged public private(set) var blurhash: String?
    
    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var updatedAt: Date
    @NSManaged public private(set) var index: NSNumber

    // many-to-one relationship
    @NSManaged public private(set) var status: Status?

}

public extension Attachment {
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(Date(), forKey: #keyPath(Attachment.createdAt))
    }
    
    @discardableResult
    static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> Attachment {
        let attachment: Attachment = context.insertObject()
        
        attachment.domain = property.domain
        attachment.index = property.index
        
        attachment.id = property.id
        attachment.typeRaw = property.typeRaw
        attachment.url = property.url
        attachment.previewURL = property.previewURL
        
        attachment.remoteURL = property.remoteURL
        attachment.metaData = property.metaData
        attachment.textURL = property.textURL
        attachment.descriptionString = property.descriptionString
        attachment.blurhash = property.blurhash

        attachment.updatedAt = property.networkDate
        
        return attachment
    }
    
    func didUpdate(at networkDate: Date) {
        self.updatedAt = networkDate
    }

}

public extension Attachment {
    struct Property {
        public let domain: String
        public let index: NSNumber
        
        public let id: ID
        public let typeRaw: String
        public let url: String
        
        public let previewURL: String?
        public let remoteURL: String?
        public let metaData: Data?
        public let textURL: String?
        public let descriptionString: String?
        public let blurhash: String?
                
        public let networkDate: Date
        
        public init(
            domain: String,
            index: Int,
            id: Attachment.ID,
            typeRaw: String,
            url: String,
            previewURL: String?,
            remoteURL: String?,
            metaData: Data?,
            textURL: String?,
            descriptionString: String?,
            blurhash: String?,
            networkDate: Date
        ) {
            self.domain = domain
            self.index = NSNumber(value: index)
            self.id = id
            self.typeRaw = typeRaw
            self.url = url
            self.previewURL = previewURL
            self.remoteURL = remoteURL
            self.metaData = metaData
            self.textURL = textURL
            self.descriptionString = descriptionString
            self.blurhash = blurhash
            self.networkDate = networkDate
        }
    }
}

extension Attachment: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \Attachment.createdAt, ascending: false)]
    }
}
