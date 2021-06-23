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
    var tableViewDiffableDataSource: UITableViewDiffableDataSource<StatusSection, Item>? { get }
    func item(for cell: UITableViewCell?, indexPath: IndexPath?) -> Item?
    func items(indexPaths: [IndexPath]) -> [Item]

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
