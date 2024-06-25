//
//  DataSourceProvider.swift
//  DataSourceProvider
//
//  Created by Cirno MainasuK on 2021-8-30.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import CoreDataStack
import MastodonSDK

enum DataSourceItem: Hashable {
    case status(record: MastodonStatus)
    case hashtag(tag: Mastodon.Entity.Tag)
    case notification(record: MastodonNotification)
    case notificationBanner(policy: Mastodon.Entity.NotificationPolicy)
    case account(account: Mastodon.Entity.Account, relationship: Mastodon.Entity.Relationship?)
}

extension DataSourceItem {
    struct Source {
        let collectionViewCell: UICollectionViewCell?
        let tableViewCell: UITableViewCell?
        let indexPath: IndexPath?
        
        init(
            collectionViewCell: UICollectionViewCell? = nil,
            tableViewCell: UITableViewCell? = nil,
            indexPath: IndexPath? = nil
        ) {
            self.collectionViewCell = collectionViewCell
            self.tableViewCell = tableViewCell
            self.indexPath = indexPath
        }
    }
}

protocol DataSourceProvider: ViewControllerWithDependencies {
    func item(from source: DataSourceItem.Source) async -> DataSourceItem?
    func update(status: MastodonStatus, intent: MastodonStatus.UpdateIntent)
}
