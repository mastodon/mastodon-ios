//
//  Status.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/2/4.
//

import CoreDataStack
import Foundation
import MastodonSDK

extension Status {
    public enum SensitiveType {
        case none
        case all
        case media(isSensitive: Bool)
    }

    public var sensitiveType: SensitiveType {
        let spoilerText = self.spoilerText ?? ""

        // cast .all sensitive when has spoiter text
        if !spoilerText.isEmpty {
            return .all
        }

        if let firstAttachment = attachments.first {
            // cast .media when has non audio media
            if firstAttachment.kind != .audio {
                return .media(isSensitive: sensitive)
            } else {
                return .none
            }
        }

        // not sensitive
        return .none
    }
}

//extension Status {
//    var authorForUserProvider: MastodonUser {
//        let author = (reblog ?? self).author
//        return author
//    }
//}

extension Status {
    public var statusURL: URL {
        if let urlString = self.url,
           let url = URL(string: urlString)
        {
            return url
        } else {
            return URL(string: "https://\(self.domain)/web/statuses/\(self.id)")!
        }
    }

    public var activityItems: [Any] {
        var items: [Any] = []
        items.append(self.statusURL)
        return items
    }
}


//extension Status {
//    var visibilityEnum: Mastodon.Entity.Status.Visibility? {
//        return visibility.flatMap { Mastodon.Entity.Status.Visibility(rawValue: $0) }
//    }
//}

extension Status {
    public var asRecord: ManagedObjectRecord<Status> {
        return .init(objectID: self.objectID)
    }
}
