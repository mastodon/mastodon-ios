//
//  ComposeStatusItem.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

import Foundation
import CoreData

enum ComposeStatusItem {
    case replyTo(tootObjectID: NSManagedObjectID)
    case toot(replyToTootObjectID: NSManagedObjectID?)
}

extension ComposeStatusItem: Hashable { }
