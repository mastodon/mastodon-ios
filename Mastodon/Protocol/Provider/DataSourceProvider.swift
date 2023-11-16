//
//  DataSourceProvider.swift
//  DataSourceProvider
//
//  Created by Cirno MainasuK on 2021-8-30.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import MastodonSDK

enum DataSourceItem: Hashable {
    case status(record: Mastodon.Entity.Status)
    case user(record: Mastodon.Entity.Account)
    case hashtag(tag: TagKind)
    case notification(record: Mastodon.Entity.Notification)
    case account(account: Mastodon.Entity.Account, relationship: Mastodon.Entity.Relationship?)
}

extension DataSourceItem {
    enum TagKind: Hashable {
        case entity(Mastodon.Entity.Tag)
    }
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
}
