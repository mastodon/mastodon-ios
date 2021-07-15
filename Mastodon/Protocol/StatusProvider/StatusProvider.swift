//
//  StatusProvider.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/5.
//

import UIKit
import Combine
import CoreData
import CoreDataStack

#if ASDK
import AsyncDisplayKit
#endif

protocol StatusProvider: NeedsDependency & DisposeBagCollectable & UIViewController {
    // async
    func status() -> Future<Status?, Never>
    func status(for cell: UITableViewCell?, indexPath: IndexPath?) -> Future<Status?, Never>
    func status(for cell: UICollectionViewCell) -> Future<Status?, Never>
    
    // sync
    var managedObjectContext: NSManagedObjectContext { get }

    @available(*, deprecated)
    var tableViewDiffableDataSource: UITableViewDiffableDataSource<StatusSection, Item>? { get }
    @available(*, deprecated)
    func item(for cell: UITableViewCell?, indexPath: IndexPath?) -> Item?
    @available(*, deprecated)
    func items(indexPaths: [IndexPath]) -> [Item]

    func statusObjectItems(indexPaths: [IndexPath]) -> [StatusObjectItem]

    #if ASDK
    func status(node: ASCellNode?, indexPath: IndexPath?) -> Status?
    #endif
}

#if ASDK
extension StatusProvider {
    func status(node: ASCellNode?, indexPath: IndexPath?) -> Status? {
        fatalError("Needs implement this")
    }
}
#endif

enum StatusObjectItem {
    case status(objectID: NSManagedObjectID)
    case homeTimelineIndex(objectID: NSManagedObjectID)
    case mastodonNotification(objectID: NSManagedObjectID)  // may not contains status 
}
