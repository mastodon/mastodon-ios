//
//  SelectedAccountItem.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/22.
//

import CoreData
import Foundation
import CoreDataStack

enum SelectedAccountItem: Hashable {
    case account(ManagedObjectRecord<MastodonUser>)
    case placeHolder(uuid: UUID)
}
