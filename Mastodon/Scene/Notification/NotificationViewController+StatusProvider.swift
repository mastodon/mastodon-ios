//
//  NotificationViewController+StatusProvider.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-1.
//

import UIKit
import Combine
import CoreData
import CoreDataStack

extension NotificationViewController: StatusProvider {
    func status() -> Future<Status?, Never> {
        return Future<Status?, Never> { promise in
            promise(.success(nil))
        }
    }

    func status(for cell: UITableViewCell?, indexPath: IndexPath?) -> Future<Status?, Never> {
        return Future<Status?, Never> { promise in
            guard let diffableDataSource = self.viewModel.diffableDataSource else {
                assertionFailure()
                promise(.success(nil))
                return
            }
            guard let indexPath = indexPath ?? cell.flatMap({ self.tableView.indexPath(for: $0) }),
                  let item = diffableDataSource.itemIdentifier(for: indexPath) else {
                promise(.success(nil))
                return
            }

            switch item {
            case .notification(let objectID, _),
                 .notificationStatus(let objectID, _):
                self.viewModel.fetchedResultsController.managedObjectContext.perform { 
                    let notification = self.viewModel.fetchedResultsController.managedObjectContext.object(with: objectID) as! MastodonNotification
                    promise(.success(notification.status))
                }
            case .bottomLoader:
                promise(.success(nil))
            }
        }
    }

    func status(for cell: UICollectionViewCell) -> Future<Status?, Never> {
        return Future<Status?, Never> { promise in
            promise(.success(nil))
        }
    }

    var managedObjectContext: NSManagedObjectContext {
        viewModel.fetchedResultsController.managedObjectContext
    }

    var tableViewDiffableDataSource: UITableViewDiffableDataSource<StatusSection, Item>? {
        return nil
    }

    func item(for cell: UITableViewCell?, indexPath: IndexPath?) -> Item? {
        return nil
    }

    func items(indexPaths: [IndexPath]) -> [Item] {
        return []
    }

    func statusObjectItems(indexPaths: [IndexPath]) -> [StatusObjectItem] {
        guard let diffableDataSource = self.viewModel.diffableDataSource else { return [] }
        let items = indexPaths.compactMap { diffableDataSource.itemIdentifier(for: $0)?.statusObjectItem }
        return items
    }

}

// MARK: - UserProvider
extension NotificationViewController: UserProvider { }
