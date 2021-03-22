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

protocol StatusProvider: NeedsDependency & DisposeBagCollectable & UIViewController {
    // async
    func toot() -> Future<Toot?, Never>
    func toot(for cell: UITableViewCell, indexPath: IndexPath?) -> Future<Toot?, Never>
    func toot(for cell: UICollectionViewCell) -> Future<Toot?, Never>
    
    // sync
    var managedObjectContext: NSManagedObjectContext { get }
    var tableViewDiffableDataSource: UITableViewDiffableDataSource<StatusSection, Item>? { get }
    func item(for cell: UITableViewCell?, indexPath: IndexPath?) -> Item?
    func items(indexPaths: [IndexPath]) -> [Item]
}
