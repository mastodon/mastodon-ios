//
//  UserItem.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-11-1.
//

import Foundation
import CoreData
import CoreDataStack
import MastodonSDK

enum UserItem: Hashable {
    case account(account: Mastodon.Entity.Account, relationship: Mastodon.Entity.Relationship?)
    case bottomLoader
    case bottomHeader(text: String)
}
