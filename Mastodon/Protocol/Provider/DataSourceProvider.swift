//
//  DataSourceProvider.swift
//  DataSourceProvider
//
//  Created by Cirno MainasuK on 2021-8-30.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import CoreDataStack
import MastodonSDK
import class CoreDataStack.Notification

enum DataSourceItem: Hashable {
    case status(record: ManagedObjectRecord<Status>)
    case user(record: ManagedObjectRecord<MastodonUser>)
    case hashtag(tag: TagKind)
    case notification(record: ManagedObjectRecord<Notification>)
}

extension DataSourceItem {
    enum TagKind: Hashable {
        case entity(Mastodon.Entity.Tag)
        case record(ManagedObjectRecord<Tag>)
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

protocol DataSourceProvider: NeedsDependency & UIViewController {
    var logger: Logger { get }
    func item(from source: DataSourceItem.Source) async -> DataSourceItem?
}
