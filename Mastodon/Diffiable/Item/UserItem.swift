//
//  UserItem.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-11-1.
//

import Foundation
import CoreData

enum UserItem: Hashable {
    case follower(objectID: NSManagedObjectID)
    case bottomLoader
    case bottomHeader(text: String)
}
