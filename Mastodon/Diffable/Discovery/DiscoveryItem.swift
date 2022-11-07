//
//  DiscoveryItem.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-13.
//

import Foundation
import MastodonSDK
import CoreDataStack

enum DiscoveryItem: Hashable {
    case hashtag(Mastodon.Entity.Tag)
    case link(Mastodon.Entity.Link)
    case user(ManagedObjectRecord<MastodonUser>)
    case bottomLoader
}
