//
//  Persistence+Card.swift
//
//
//  Created by MainasuK on 2021-12-9.
//

import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import os.log

extension Persistence.Card {

    public struct PersistContext {
        public let domain: String
        public let entity: Mastodon.Entity.Card
        public let me: MastodonUser?
        public let log = Logger(subsystem: "Card", category: "Persistence")
        public init(
            domain: String,
            entity: Mastodon.Entity.Card,
            me: MastodonUser?
        ) {
            self.domain = domain
            self.entity = entity
            self.me = me
        }
    }

    public struct PersistResult {
        public let card: Card
        public let isNewInsertion: Bool

        public init(
            card: Card,
            isNewInsertion: Bool
        ) {
            self.card = card
            self.isNewInsertion = isNewInsertion
        }

        #if DEBUG
        public let logger = Logger(subsystem: "Persistence.MastodonCard.PersistResult", category: "Persist")
        public func log() {
            let pollInsertionFlag = isNewInsertion ? "+" : "-"
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(pollInsertionFlag)](\(card.title)):")
        }
        #endif
    }

    public static func create(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> PersistResult {
        var type: MastodonCardType {
            switch context.entity.type {
            case .link:                 return .link
            case .photo:                return .photo
            case .video:                return .video
            case .rich:                 return ._other(context.entity.type.rawValue)
            case ._other(let rawValue): return ._other(rawValue)
            }
        }

        let property = Card.Property(
            urlRaw: context.entity.url,
            title: context.entity.title,
            desc: context.entity.description,
            type: type,
            authorName: context.entity.authorName,
            authorURLRaw: context.entity.authorURL,
            providerName: context.entity.providerName,
            providerURLRaw: context.entity.providerURL,
            width: Int64(context.entity.width ?? 0),
            height: Int64(context.entity.height ?? 0),
            image: context.entity.image,
            embedURLRaw: context.entity.embedURL,
            blurhash: context.entity.blurhash,
            html: context.entity.html.flatMap { $0.isEmpty ? nil : $0 }
        )

        let card = Card.insert(
            into: managedObjectContext,
            property: property
        )

        return PersistResult(
            card: card,
            isNewInsertion: true
        )
    }

}
