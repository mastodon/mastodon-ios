//
//  RecommendAccountItem.swift
//  Mastodon
//
//  Created by MainasuK on 2022-2-10.
//

import Foundation
import CoreDataStack

enum RecommendAccountItem: Hashable {
    case account(ManagedObjectRecord<MastodonUser>)
}
