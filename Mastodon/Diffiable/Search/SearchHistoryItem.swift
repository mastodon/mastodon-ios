//
//  SearchHistoryItem.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-15.
//

import Foundation
import CoreData
import CoreDataStack

enum SearchHistoryItem: Hashable {
    case hashtag(ManagedObjectRecord<Tag>)
    case user(ManagedObjectRecord<MastodonUser>)
}
