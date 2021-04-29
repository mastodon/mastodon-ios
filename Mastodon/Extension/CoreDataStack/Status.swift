//
//  Status.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/2/4.
//

import Foundation
import CoreDataStack
import MastodonSDK

extension Status.Property {
    init(entity: Mastodon.Entity.Status, domain: String, networkDate: Date) {
        self.init(
            domain: domain,
            id: entity.id,
            uri: entity.uri,
            createdAt: entity.createdAt,
            content: entity.content,
            visibility: entity.visibility?.rawValue,
            sensitive: entity.sensitive ?? false,
            spoilerText: entity.spoilerText,
            reblogsCount: NSNumber(value: entity.reblogsCount),
            favouritesCount: NSNumber(value: entity.favouritesCount),
            repliesCount: entity.repliesCount.flatMap { NSNumber(value: $0) },
            url: entity.uri,
            inReplyToID: entity.inReplyToID,
            inReplyToAccountID: entity.inReplyToAccountID,
            language: entity.language,
            text: entity.text,
            networkDate: networkDate
        )
    }
}

extension Status {
    
    enum SensitiveType {
        case none
        case all
        case media(isSensitive: Bool)
    }
    
    var sensitiveType: SensitiveType {
        let spoilerText = self.spoilerText ?? ""
        
        // cast .all sensitive when has spoiter text
        if !spoilerText.isEmpty {
            return .all
        }
        
        if let firstAttachment = mediaAttachments?.first {
            // cast .media when has non audio media
            if firstAttachment.type != .audio {
                return .media(isSensitive: sensitive)
            } else {
                return .none
            }
        }
        
        // not sensitive
        return .none
    }
    
}

extension Status {
    var authorForUserProvider: MastodonUser {
        let author = (reblog ?? self).author
        return author
    }
}
